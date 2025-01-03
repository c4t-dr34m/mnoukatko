/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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
import CoreBluetooth
import CoreData
import MeshtasticProtobufs
import OSLog

extension BLEManager: CBPeripheralDelegate {
	func peripheral(
		_ peripheral: CBPeripheral,
		didDiscoverServices error: Error?
	) {
		guard let services = peripheral.services else {
			return
		}

		for service in services where service.uuid == BluetoothUUID.meshtasticService {
			peripheral.discoverCharacteristics(
				[
					BluetoothUUID.toRadio,
					BluetoothUUID.fromRadio,
					BluetoothUUID.fromNum,
					BluetoothUUID.logRadioLegacy,
					BluetoothUUID.logRadio
				],
				for: service
			)
		}
	}

	func peripheral(
		_ peripheral: CBPeripheral,
		didDiscoverCharacteristicsFor service: CBService,
		error: Error?
	) {
		let deviceName = peripheral.name ?? peripheral.identifier.uuidString

		if let error {
			Logger.services.error(
				"🚫 [BLE] Discover Characteristics error for \(deviceName): \(error.localizedDescription); disconnecting device"
			)

			disconnectDevice()

			return
		}

		guard let characteristics = service.characteristics else {
			return
		}

		for characteristic in characteristics {
			Logger.services.debug("\(deviceName) characteristic discovered: \(characteristic.uuid.uuidString)")

			switch characteristic.uuid {
			case BluetoothUUID.toRadio:
				characteristicToRadio = characteristic

			case BluetoothUUID.fromRadio:
				characteristicFromRadio = characteristic
				peripheral.readValue(for: characteristicFromRadio)

			case BluetoothUUID.fromNum:
				characteristicFromNum = characteristic
				peripheral.setNotifyValue(true, for: characteristic)

			case BluetoothUUID.logRadioLegacy:
				characteristicLogRadioLegacy = characteristic
				peripheral.setNotifyValue(true, for: characteristic)

			case BluetoothUUID.logRadio:
				characteristicLogRadio = characteristic
				peripheral.setNotifyValue(true, for: characteristic)

			default:
				break
			}
		}

		let nodeConfig = NodeConfig(bleManager: self, context: context)
		lastConfigNonce = nodeConfig.sendWantConfig()
	}

	func peripheral(
		_ peripheral: CBPeripheral,
		didUpdateValueFor characteristic: CBCharacteristic,
		error: Error?
	) {
		if let error {
			Logger.services.error(
				"🚫 [BLE] didUpdateValueFor Characteristic error \(error.localizedDescription, privacy: .public)"
			)

			let errorCode = (error as NSError).code
			if errorCode == 5 || errorCode == 15 {
				// BLE PIN connection errors
				// 5 CBATTErrorDomain Code=5 "Authentication is insufficient."
				// 15 CBATTErrorDomain Code=15 "Encryption is insufficient."
				lastConnectionError = "Bluetooth authentication or encryption is insufficient. Please check connecting again and pay attention to the PIN code."
				disconnectDevice(reconnect: false)
			}

			return
		}

		switch characteristic.uuid {
		case BluetoothUUID.logRadio:
			guard
				let value = characteristic.value,
				let logRecord = try? LogRecord(serializedData: value)
			else {
				return
			}

			handleRadioLog(
				"\(logRecord.level.rawValue) | [\(logRecord.source)] \(logRecord.message)"
			)

		case BluetoothUUID.logRadioLegacy:
			guard
				let value = characteristic.value,
				let log = String(data: value, encoding: .utf8)
			else {
				return
			}

			handleRadioLog(log)

		case BluetoothUUID.fromRadio:
			guard let value = characteristic.value else {
				return
			}

			processRadioData(value: value)

		default:
			break
		}

		if let characteristicFromRadio {
			peripheral.readValue(for: characteristicFromRadio)
		}
	}

	// swiftlint:disable:next cyclomatic_complexity
	func processRadioData(value: Data) {
		guard let info = try? FromRadio(serializedData: value) else {
			return
		}

		let num = getConnectedDevice()?.num ?? -1

		switch info.packet.decoded.portnum {
		case .unknownApp:
			guard var device = getConnectedDevice() else {
				break
			}

			// MyInfo from initial connection
			if info.myInfo.isInitialized, info.myInfo.myNodeNum > 0 {
				if let myInfo = myInfoPacket(
					myInfo: info.myInfo,
					peripheralId: device.id,
					context: context
				) {
					let nodeNumInt = Int(myInfo.myNodeNum)
					UserDefaults.preferredPeripheralNumList.removeAll(where: { num in
						num == nodeNumInt
					})
					UserDefaults.preferredPeripheralNumList.insert(nodeNumInt, at: 0)

					device.num = myInfo.myNodeNum
					device.name = myInfo.bleName ?? "Unknown node"
					device.longName = myInfo.bleName ?? "Unknown node"

					currentDevice.update(with: device)
				}
			}

			// NodeInfo
			if info.nodeInfo.num > 0 {
				if
					let nodeInfo = nodeInfoPacket(
						nodeInfo: info.nodeInfo,
						channel: info.packet.channel,
						context: context
					),
					let user = nodeInfo.user,
					device.num == nodeInfo.num
				{
					device.shortName = user.shortName ?? "?"
					device.longName = user.longName ?? "Unknown node"

					currentDevice.update(with: device)
				}
			}

			// Channels
			if info.channel.isInitialized {
				channelPacket(
					channel: info.channel,
					fromNum: Int64(truncatingIfNeeded: device.num),
					context: context
				)
			}

			// Config
			if info.config.isInitialized, !isInvalidFwVersion {
				localConfig(
					config: info.config,
					context: context,
					nodeNum: Int64(truncatingIfNeeded: device.num),
					nodeLongName: device.longName
				)
			}

			// Module Config
			if
				device.num != 0,
				info.moduleConfig.isInitialized,
				!isInvalidFwVersion
			{
				moduleConfig(
					config: info.moduleConfig,
					context: context,
					nodeNum: Int64(truncatingIfNeeded: device.num),
					nodeLongName: device.longName
				)
			}

			// Device Metadata
			if info.metadata.firmwareVersion.count > 0, !isInvalidFwVersion {
				device.firmwareVersion = info.metadata.firmwareVersion

				currentDevice.update(with: device)

				deviceMetadataPacket(
					metadata: info.metadata,
					fromNum: device.num,
					context: context
				)

				if let lastDotIndex = info.metadata.firmwareVersion.lastIndex(of: ".") {
					let version = info.metadata.firmwareVersion[...lastDotIndex]
					connectedVersion = String(version.dropLast())
					UserDefaults.firmwareVersion = connectedVersion
				}
				else {
					isInvalidFwVersion = true
					connectedVersion = "0.0.0"
				}

				let supportedVersion = connectedVersion == "0.0.0"
				|| [.orderedAscending, .orderedSame].contains(minimumVersion.compare(connectedVersion, options: .numeric))

				if !supportedVersion {
					isInvalidFwVersion = true
					lastConnectionError = "🚨" + "update.firmware".localized

					return
				}
			}

		case .textMessageApp, .detectionSensorApp:
			textMessageAppPacket(
				packet: info.packet,
				wantRangeTestPackets: wantRangeTestPackets,
				connectedNode: num,
				context: context,
				appState: appState
			)

		case .positionApp:
			coreDataTools.upsertPositionPacket(
				packet: info.packet,
				connectedDevice: getConnectedDevice(),
				context: context
			)

		case .waypointApp:
			waypointPacket(packet: info.packet, context: context)

		case .nodeinfoApp:
			guard !isInvalidFwVersion else {
				break
			}

			coreDataTools.upsertNodeInfoPacket(
				packet: info.packet,
				connectedDevice: getConnectedDevice(),
				context: context
			)
			onInfoReceived(num: Int64(info.packet.from))

		case .routingApp:
			guard !isInvalidFwVersion else {
				break
			}

			routingPacket(
				packet: info.packet,
				connectedNodeNum: num,
				context: context
			)

		case .adminApp:
			adminAppPacket(packet: info.packet, context: context)

		case .replyApp:
			textMessageAppPacket(
				packet: info.packet,
				wantRangeTestPackets: wantRangeTestPackets,
				connectedNode: num,
				context: context,
				appState: appState
			)

		case .storeForwardApp:
			guard wantStoreAndForwardPackets else {
				break
			}

			storeAndForwardPacket(
				packet: info.packet,
				connectedNodeNum: num,
				context: context
			)

		case .rangeTestApp:
			guard wantRangeTestPackets else {
				break
			}

			textMessageAppPacket(
				packet: info.packet,
				wantRangeTestPackets: true,
				connectedNode: num,
				context: context,
				appState: appState
			)

		case .telemetryApp:
			guard !isInvalidFwVersion else {
				break
			}

			telemetryPacket(
				packet: info.packet,
				connectedNode: num,
				context: context
			)

		case .tracerouteApp:
			guard
				let routingMessage = try? RouteDiscovery(serializedData: info.packet.decoded.payload),
				!routingMessage.route.isEmpty
			else {
				break
			}

			guard
				let traceRoute = coreDataTools.getTraceRoute(
					id: Int64(info.packet.decoded.requestID),
					context: context
				)
			else {
				break
			}

			traceRoute.response = true
			traceRoute.route = routingMessage.route

			var hopNodes: [TraceRouteHopEntity] = []
			for node in routingMessage.route {
				var hopNode = coreDataTools.getNodeInfo(id: Int64(node), context: context)
				if hopNode == nil, node != 4294967295 {
					hopNode = NodeInfoEntity.create(for: Int64(node), with: context)
				}

				let traceRouteHop = TraceRouteHopEntity(context: context)
				traceRouteHop.time = Date.now

				if
					let hopNode,
					let mostRecent = hopNode.positions?.lastObject as? PositionEntity,
					let time = mostRecent.time,
					// swiftlint:disable:next force_unwrapping
					time >= Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
				{
					traceRouteHop.latitudeI = mostRecent.latitudeI
					traceRouteHop.longitudeI = mostRecent.longitudeI
					traceRouteHop.altitude = mostRecent.altitude

					traceRoute.hasPositions = true
				}
				else {
					traceRoute.hasPositions = false
				}

				if let hopNode {
					traceRouteHop.num = hopNode.num
					traceRouteHop.name = hopNode.user?.longName ?? "Unknown node"

					hopNode.setLastHeard(at: info.packet.rxTime, by: getConnectedDevice())

					hopNodes.append(traceRouteHop)
				}
			}

			traceRoute.hops = NSOrderedSet(array: hopNodes)

			dataDebounce.emit { [weak self] in
				await self?.saveData()
			}

			onTraceRouteReceived(for: traceRoute.node)

			if let user = traceRoute.node?.user {
				notificationManager.queue(
					notification: Notification(
						title: "Trace Route",
						subtitle: user.longName,
						body: "Trace route was received",
						path: URL(string: "\(AppConstants.scheme):///nodes?nodenum=\(user.num)")
					)
				)
			}

		case .paxcounterApp:
			paxCounterPacket(packet: info.packet, context: context)

		default:
			break
		}

		let id = info.configCompleteID
		if id != UInt32.min, id == lastConfigNonce {
			isInvalidFwVersion = false
			lastConnectionError = ""
			isSubscribed = true

			if num > 0 {
				let fetchNodeInfoRequest = NodeInfoEntity.fetchRequest()
				fetchNodeInfoRequest.predicate = NSPredicate(
					format: "num == %lld",
					Int64(num)
				)

				if
					let fetchedNodeInfo = try? context.fetch(fetchNodeInfoRequest),
					!fetchedNodeInfo.isEmpty
				{
					let node = fetchedNodeInfo[0]

					// Set initial unread message badge states
					appState.unreadChannelMessages = node.myInfo?.unreadMessages ?? 0
					appState.unreadDirectMessages = node.user?.unreadMessages ?? 0

					if let rtConf = node.rangeTestConfig, rtConf.enabled {
						wantRangeTestPackets = true
					}

					if let sfConf = node.storeForwardConfig, sfConf.enabled {
						wantStoreAndForwardPackets = true
					}
				}
			}

			if UserDefaults.provideLocation {
				let timer = Timer.scheduledTimer(
					timeInterval: TimeInterval(UserDefaults.provideLocationInterval),
					target: self,
					selector: #selector(positionTimerFired),
					userInfo: context,
					repeats: true
				)
				RunLoop.current.add(timer, forMode: .common)

				positionTimer = timer
			}

			devicesDelegate?.onWantConfigFinished()
			AnalyticEvents.trackBLEEvent(for: .wantConfigComplete, status: .success)

			return
		}
	}

	private func storeAndForwardPacket(
		packet: MeshPacket,
		connectedNodeNum: Int64,
		context: NSManagedObjectContext
	) {
		if let storeAndForwardMessage = try? StoreAndForward(serializedData: packet.decoded.payload) {
			switch storeAndForwardMessage.rr {
			case .routerHeartbeat:
				/// When we get a router heartbeat we know there is a store and forward node on the network
				/// Check if it is the primary S&F Router and save the timestamp of the last
				/// heartbeat so that we can show the request message history menu item on node
				/// long press if the router has been seen recently
				guard
					storeAndForwardMessage.heartbeat.secondary != 0,
					let router = coreDataTools.getNodeInfo(
						id: Int64(packet.from),
						context: context
					)
				else {
					return
				}

				if router.storeForwardConfig != nil {
					router.storeForwardConfig?.enabled = true
					router.storeForwardConfig?.isRouter = storeAndForwardMessage.heartbeat.secondary == 0
					router.storeForwardConfig?.lastHeartbeat = Date.now
				}
				else {
					let newConfig = StoreForwardConfigEntity(context: context)
					newConfig.enabled = true
					newConfig.isRouter = storeAndForwardMessage.heartbeat.secondary == 0
					newConfig.lastHeartbeat = Date.now

					router.storeForwardConfig = newConfig
				}

				dataDebounce.emit { [weak self] in
					await self?.saveData()
				}

			case .routerHistory:
				/// Set the Router History Last Request Value
				guard let routerNode = coreDataTools.getNodeInfo(id: Int64(packet.from), context: context) else {
					return
				}

				if routerNode.storeForwardConfig != nil {
					routerNode.storeForwardConfig?.lastRequest = Int32(storeAndForwardMessage.history.lastRequest)
				}
				else {
					let newConfig = StoreForwardConfigEntity(context: context)
					newConfig.lastRequest = Int32(storeAndForwardMessage.history.lastRequest)

					routerNode.storeForwardConfig = newConfig
				}

				dataDebounce.emit { [weak self] in
					await self?.saveData()
				}

			case .routerTextDirect:
				textMessageAppPacket(
					packet: packet,
					wantRangeTestPackets: false,
					connectedNode: connectedNodeNum,
					storeForward: true,
					context: context,
					appState: appState
				)

			case .routerTextBroadcast:
				textMessageAppPacket(
					packet: packet,
					wantRangeTestPackets: false,
					connectedNode: connectedNodeNum,
					storeForward: true,
					context: context,
					appState: appState
				)

			default:
				return
			}
		}
	}

	private func handleRadioLog(_ message: String) {
		Logger.radio.info("\(message, privacy: .public)")
	}

	@objc
	private func positionTimerFired(timer: Timer) {
		guard
			let connectedDevice = getConnectedDevice(),
			UserDefaults.provideLocation
		else {
			return
		}

		sendPosition(
			channel: 0,
			destNum: connectedDevice.num,
			wantResponse: false
		)
	}
}
