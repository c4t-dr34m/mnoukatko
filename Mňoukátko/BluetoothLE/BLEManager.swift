/*
Mňoukátko - a Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
Copyright © 2024 Radovan Paška

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
import CocoaMQTT
import CoreBluetooth
import CoreData
import FirebaseAnalytics
import Foundation
import MapKit
import MeshtasticProtobufs
import OSLog
import SwiftUI

// swiftlint:disable file_length
final class BLEManager: NSObject, ObservableObject {
	let appState: AppState
	let context: NSManagedObjectContext
	let coreDataTools = CoreDataTools()
	let notificationManager = LocalNotificationManager()
	let minimumVersion = "2.0.0"
	let dataDebounce = Debounce<() async -> Void>(duration: .milliseconds(500)) { action in
		await action()
	}

	@Published
	var devices = [Device]()
	@Published
	var currentDevice: CurrentDevice
	@Published
	var info: String?
	@Published
	var infoChangeCount = 0
	@Published
	var lastConnectionError: String
	@Published
	var isInvalidFwVersion = false
	@Published
	var isSwitchedOn = false
	@Published
	var automaticallyReconnect = true {
		didSet {
			guard oldValue != self.automaticallyReconnect else {
				return
			}

			Logger.app.debug("BLE manager auto-reconnect changed: \(self.automaticallyReconnect)")
		}
	}
	@Published
	var mqttConnected = false
	@Published
	var mqttError = ""

	var centralManager: CBCentralManager?
	var nodeNames = [Int64: String]()
	var infoLastChanged: Date?
	var devicesDelegate: DevicesDelegate?
	var deviceWatchingTimer: Timer?
	var mqttManager: MQTTManager?
	var connectedVersion: String
	var isConnecting = false
	var isConnected = false {
		didSet {
			if !isConnected {
				info = nil
				infoLastChanged = nil
				infoChangeCount = 0
			}
		}
	}
	var isSubscribed = false
	var timeoutTimer: Timer?
	var timeoutCount = 0
	var positionTimer: Timer?
	var wantRangeTestPackets = false
	var wantStoreAndForwardPackets = false
	var lastConfigNonce = UInt32.min
	var characteristicToRadio: CBCharacteristic?
	var characteristicFromRadio: CBCharacteristic?
	var characteristicFromNum: CBCharacteristic?
	var characteristicLogRadio: CBCharacteristic?
	var characteristicLogRadioLegacy: CBCharacteristic?

	init(
		appState: AppState,
		context: NSManagedObjectContext
	) {
		self.appState = appState
		self.context = context
		self.mqttManager = MQTTManager()
		self.currentDevice = CurrentDevice(context: context)

		self.lastConnectionError = ""
		self.connectedVersion = "0.0.0"

		super.init()

		NotificationCenter.default.addObserver(
			forName: .onboardingDone,
			object: nil,
			queue: nil,
			using: { [weak self] _ in
				self?.initCentral()
			}
		)
		initCentral()
	}

	func initCentral() {
		guard UserDefaults.onboardingDone else {
			return
		}

		Logger.app.debug("Initializing central...")

		let central = CBCentralManager()
		central.delegate = self
		isSwitchedOn = central.state == .poweredOn

		centralManager = central
	}

	func getConnectedDevice() -> Device? {
		currentDevice.getConnectedDevice()
	}

	func startScanning() {
		guard let centralManager, !centralManager.isScanning else {
			return
		}

		guard centralManager.state == .poweredOn else {
			Logger.services.info(
				"Peripheral scanning denied. Central state: \(centralManager.state.name)"
			)
			return
		}

		centralManager.scanForPeripherals(
			withServices: [BluetoothUUID.meshtasticService],
			options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
		)

		Logger.services.debug("Device scanning started")

		if !devices.isEmpty {
			onDevicesChange() // Check devices we got before scanning started
		}

		deviceWatchingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
			self?.onDevicesChange()
		}
	}

	func stopScanning() {
		guard let centralManager, centralManager.isScanning else {
			return
		}

		Logger.services.debug("Device scanning stopped")

		centralManager.stopScan()
		deviceWatchingTimer?.invalidate()
	}

	func onDevicesChange() {
		devicesDelegate?.onChange(devices: devices)

		guard automaticallyReconnect, getConnectedDevice() == nil else {
			return
		}

		if let first = devices.sortedByPreference().first {
			// connect to first preferred device visible
			connectTo(peripheral: first.peripheral)
		}
	}

	func connectTo(peripheral: CBPeripheral) {
		guard let centralManager else {
			return
		}

		if peripheral.state == .connecting {
			return
		}

		if peripheral.state == .connected {
			if peripheral.identifier == currentDevice.device?.peripheral.identifier {
				Logger.services.debug(
					"Device \(peripheral.name ?? peripheral.identifier.uuidString) is already connected"
				)

				devicesDelegate?.onDeviceConnected(name: peripheral.name)

				return
			}
			else {
				Logger.services.debug("We want to connect to different device. Disconnecting...")

				disconnectDevice()
			}
		}

		Logger.services.debug(
			"Attempting to connect to \(peripheral.name ?? peripheral.identifier.uuidString) [central:\(centralManager.state.name)]"
		)

		isConnecting = true
		lastConnectionError = ""
		automaticallyReconnect = true
		timeoutTimer?.invalidate()

		centralManager.connect(peripheral)

		timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
			guard let self else { return }

			Logger.services.warning("Bluetooth connection timed out; attempt: \(self.timeoutCount)")

			timeoutCount += 1
			lastConnectionError = ""

			guard timeoutCount >= 10 else {
				return
			}

			if let device = currentDevice.device {
				centralManager.cancelPeripheralConnection(device.peripheral)
			}

			currentDevice.clear()
			isConnected = false
			isConnecting = false
			timeoutCount = 0
			timeoutTimer?.invalidate()
			lastConnectionError = "Bluetooth connection timed out"

			Analytics.logEvent(AnalyticEvents.bleTimeout.id, parameters: nil)
		}

		Analytics.logEvent(AnalyticEvents.bleConnect.id, parameters: nil)
	}

	func cancelPeripheralConnection() {
		if let mqttClientProxy = mqttManager?.client, mqttConnected {
			mqttClientProxy.disconnect()
		}

		currentDevice.clear()

		isConnecting = false
		isConnected = false
		isSubscribed = false
		isInvalidFwVersion = false
		characteristicFromRadio = nil
		connectedVersion = "0.0.0"
		automaticallyReconnect = false
		timeoutTimer?.invalidate()

		Analytics.logEvent(AnalyticEvents.bleCancelConnecting.id, parameters: nil)
	}

	func disconnectDevice(reconnect: Bool = true) {
		guard let device = currentDevice.device else {
			return
		}

		if let mqttClientProxy = mqttManager?.client, mqttConnected {
			mqttClientProxy.disconnect()
		}

		centralManager?.cancelPeripheralConnection(device.peripheral)
		currentDevice.clear()

		isConnected = false
		isSubscribed = false
		isInvalidFwVersion = false
		characteristicFromRadio = nil
		connectedVersion = "0.0.0"
		automaticallyReconnect = reconnect

		Analytics.logEvent(AnalyticEvents.bleDisconnect.id, parameters: nil)
	}

	func connectMQTT(config: MQTTConfigEntity? = nil) {
		if let config, config.enabled {
			let manager = MQTTManager()
			manager.delegate = self
			manager.connect(config: config)

			mqttManager = manager
		}
		else if canHaveDemo() {
			let manager = MQTTManager()
			manager.delegate = self
			manager.connectDefaults()

			mqttManager = manager
		}
	}

	func disconnectMQTT() {
		mqttManager?.disconnect()
		mqttManager?.delegate = nil
		mqttManager = nil
	}

	func canHaveDemo() -> Bool {
		false // disabled forever

		/*
		guard UserDefaults.preferredPeripheralId.isEmpty else {
			return false
		}

		guard !isConnecting, !isConnected else {
			return false
		}

		return true
		*/
	}

	func setIsInvalidFwVersion() {
		isInvalidFwVersion = true
	}

	@discardableResult
	func sendTraceRouteRequest(destNum: Int64, wantResponse: Bool) -> Bool {
		guard let connectedDevice = getConnectedDevice() else {
			return false
		}

		guard let serializedData = try? RouteDiscovery().serializedData() else {
			return false
		}

		var dataMessage = DataMessage()
		dataMessage.payload = serializedData
		dataMessage.portnum = PortNum.tracerouteApp
		dataMessage.wantResponse = true

		var meshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(destNum)
		meshPacket.from = UInt32(connectedDevice.num)
		meshPacket.wantAck = true
		meshPacket.decoded = dataMessage

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		guard let binaryData = try? toRadio.serializedData() else {
			return false
		}

		if let connectedDevice = getConnectedDevice() {
			connectedDevice.peripheral.writeValue(
				binaryData,
				for: characteristicToRadio,
				type: .withResponse
			)

			Analytics.logEvent(AnalyticEvents.bleTraceRoute.id, parameters: nil)

			let nodeRequest = NodeInfoEntity.fetchRequest()
			nodeRequest.predicate = NSPredicate(
				format: "num IN %@",
				[destNum, connectedDevice.num]
			)

			guard let nodes = try? context.fetch(nodeRequest) else {
				return false
			}

			let receivingNode = nodes.first(where: {
				$0.num == destNum
			})
			let connectedNode = nodes.first(where: {
				$0.num == connectedDevice.num
			})

			let traceRoute = TraceRouteEntity(context: context)
			traceRoute.id = Int64(meshPacket.id)
			traceRoute.time = Date()
			traceRoute.node = receivingNode

			// swiftlint:disable:next force_unwrapping
			let lastDay = Calendar.current.date(byAdding: .hour, value: -24, to: Date.now)!
			if
				let positions = connectedNode?.positions,
				let mostRecent = positions.lastObject as? PositionEntity,
				let time = mostRecent.time,
				time >= lastDay
			{
				traceRoute.altitude = mostRecent.altitude
				traceRoute.latitudeI = mostRecent.latitudeI
				traceRoute.longitudeI = mostRecent.longitudeI
				traceRoute.hasPositions = true
			}

			dataDebounce.emit { [weak self] in
				await self?.saveData()
			}

			return true
		}

		return false
	}

	func sendMessage(
		message: String,
		toUserNum: Int64,
		channel: Int32,
		isEmoji: Bool,
		replyID: Int64
	) -> Bool {
		guard
			let connectedDevice = getConnectedDevice(),
			!message.isEmpty
		else {
			AnalyticEvents.trackBLEEvent(for: .message, status: .failureProcess)
			return false
		}

		let fromUserNum: Int64 = connectedDevice.num
		let messageUsers = UserEntity.fetchRequest()
		messageUsers.predicate = NSPredicate(format: "num IN %@", [fromUserNum, Int64(toUserNum)])

		guard
			let fetchedUsers = try? context.fetch(messageUsers),
			!fetchedUsers.isEmpty
		else {
			AnalyticEvents.trackBLEEvent(for: .message, status: .failureProcess)
			return false
		}

		let newMessage = MessageEntity(context: context)
		newMessage.messageId = Int64(UInt32.random(in: UInt32(UInt8.max)..<UInt32.max))
		newMessage.messageTimestamp = Int32(Date.now.timeIntervalSince1970)
		newMessage.receivedACK = false
		newMessage.read = true
		if toUserNum > 0 {
			newMessage.toUser = fetchedUsers.first(where: {
				$0.num == toUserNum
			})
			newMessage.toUser?.lastMessage = Date()
		}
		newMessage.fromUser = fetchedUsers.first(where: {
			$0.num == fromUserNum
		})
		newMessage.isEmoji = isEmoji
		newMessage.admin = false
		newMessage.channel = channel
		if replyID > 0 {
			newMessage.replyID = replyID
		}
		newMessage.messagePayload = message
		newMessage.messagePayloadMarkdown = generateMessageMarkdown(message: message)
		newMessage.read = true

		var dataMessage = DataMessage()
		dataMessage.portnum = PortNum.textMessageApp
		dataMessage.payload = message
			.replacingOccurrences(of: "’", with: "'")
			.replacingOccurrences(of: "”", with: "\"")
			.data(using: String.Encoding.utf8)!

		var meshPacket = MeshPacket()
		meshPacket.id = UInt32(newMessage.messageId)
		if toUserNum > 0 {
			meshPacket.to = UInt32(toUserNum)
		}
		else {
			meshPacket.to = Constants.maximumNodeNum
		}
		meshPacket.channel = UInt32(channel)
		meshPacket.from	= UInt32(fromUserNum)
		meshPacket.decoded = dataMessage
		meshPacket.decoded.emoji = isEmoji ? 1 : 0
		if replyID > 0 {
			meshPacket.decoded.replyID = UInt32(replyID)
		}
		meshPacket.wantAck = true

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		guard let binaryData: Data = try? toRadio.serializedData() else {
			AnalyticEvents.trackBLEEvent(for: .message, status: .failureProcess)
			return false
		}

		connectedDevice.peripheral.writeValue(
			binaryData,
			for: characteristicToRadio,
			type: .withResponse
		)

		dataDebounce.emit { [weak self] in
			if let status = await self?.saveData(), status{
				AnalyticEvents.trackBLEEvent(for: .message, status: .success)
			}
			else {
				AnalyticEvents.trackBLEEvent(for: .message, status: .failureSend)
			}
		}

		return true
	}

	@discardableResult
	func sendPosition(channel: Int32, destNum: Int64, wantResponse: Bool) -> Bool {
		guard
			let connectedDevice = getConnectedDevice(),
			let positionPacket = getPhonePosition()
		else {
			AnalyticEvents.trackBLEEvent(for: .position, status: .failureProcess)
			return false
		}

		var meshPacket = MeshPacket()
		meshPacket.to = UInt32(destNum)
		meshPacket.channel = UInt32(channel)
		meshPacket.from = UInt32(connectedDevice.num)

		var dataMessage = DataMessage()
		if let serializedData: Data = try? positionPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.positionApp
			dataMessage.wantResponse = wantResponse
			meshPacket.decoded = dataMessage
		}
		else {
			AnalyticEvents.trackBLEEvent(for: .position, status: .failureProcess)
			return false
		}

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		guard let binaryData: Data = try? toRadio.serializedData() else {
			AnalyticEvents.trackBLEEvent(for: .position, status: .failureProcess)
			return false
		}

		connectedDevice.peripheral.writeValue(
			binaryData,
			for: characteristicToRadio,
			type: .withResponse
		)

		AnalyticEvents.trackBLEEvent(for: .position, status: .success)

		return true
	}

	func getPhonePosition() -> Position? {
		guard let lastLocation = LocationManager.shared.getLocation() else {
			return nil
		}

		let timestamp = lastLocation.timestamp

		var positionPacket = Position()
		positionPacket.time = UInt32(timestamp.timeIntervalSince1970)
		positionPacket.timestamp = UInt32(timestamp.timeIntervalSince1970)
		positionPacket.latitudeI = Int32(lastLocation.coordinate.latitude * 1e7)
		positionPacket.longitudeI = Int32(lastLocation.coordinate.longitude * 1e7)
		positionPacket.altitude = Int32(lastLocation.altitude)
		positionPacket.satsInView = UInt32(0)

		let currentSpeed = lastLocation.speed
		if currentSpeed > 0, !currentSpeed.isNaN || !currentSpeed.isInfinite {
			positionPacket.groundSpeed = UInt32(currentSpeed)
		}

		let currentHeading = lastLocation.course
		if currentHeading > 0, currentHeading <= 360, !currentHeading.isNaN || !currentHeading.isInfinite {
			positionPacket.groundTrack = UInt32(currentHeading)
		}

		return positionPacket
	}

	@discardableResult
	func saveData() async -> Bool {
		await context.perform { [weak self] in
			guard let self, self.context.hasChanges else {
				return false
			}

			do {
				try self.context.save()

				return true
			}
			catch {
				self.context.rollback()

				return false
			}
		}
	}

	@objc
	private func timeoutTimerFired() {
		Logger.services.warning("Bluetooth connection timed out; attempt: \(self.timeoutCount)")

		timeoutCount += 1
		lastConnectionError = ""

		if timeoutCount >= 10 {
			if let device = currentDevice.device {
				centralManager?.cancelPeripheralConnection(device.peripheral)
			}

			currentDevice.clear()
			isConnected = false
			isConnecting = false
			timeoutCount = 0
			timeoutTimer?.invalidate()
			lastConnectionError = "Bluetooth connection timed out"

			Analytics.logEvent(AnalyticEvents.bleTimeout.id, parameters: nil)
		}
	}
}
// swiftlint:enable file_length
