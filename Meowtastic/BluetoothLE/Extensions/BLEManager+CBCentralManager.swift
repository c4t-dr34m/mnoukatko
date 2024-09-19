import CoreBluetooth
import OSLog

extension BLEManager: CBCentralManagerDelegate {
	func centralManagerDidUpdateState(
		_ central: CBCentralManager
	) {
		Logger.services.info("Central manager changed state to: \(central.state.name)")

		if central.state == .poweredOn {
			isSwitchedOn = true

			if !central.isScanning {
				startScanning()
			}
		}
		else {
			isSwitchedOn = false
		}
	}

	func centralManager(
		_ central: CBCentralManager,
		didDiscover peripheral: CBPeripheral,
		advertisementData: [String: Any],
		rssi RSSI: NSNumber
	) {
		let id = peripheral.identifier.uuidString
		if !devices.contains(where: { device in
			device.id == id
		}) {
			Logger.services.info("New peripheral discovered: \(peripheral.name ?? peripheral.identifier.uuidString)")
		}

		let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
		let device = Device(
			id: peripheral.identifier.uuidString,
			num: 0,
			name: name ?? "Unknown",
			shortName: "?",
			longName: name ?? "Unknown",
			firmwareVersion: "Unknown",
			rssi: RSSI.intValue,
			lastUpdate: Date.now,
			peripheral: peripheral
		)
		let index = devices.map { device in
			device.peripheral
		}
			.firstIndex(of: peripheral)

		if let peripheralIndex = index {
			devices[peripheralIndex] = device
		}
		else {
			devices.append(device)
		}

		// swiftlint:disable:next force_unwrapping
		let visibleDuration = Calendar.current.date(byAdding: .second, value: -5, to: .now)!

		devices.removeAll(where: {
			$0.lastUpdate < visibleDuration
		})

		onDevicesChange()
	}

	func centralManager(
		_ central: CBCentralManager,
		didConnect peripheral: CBPeripheral
	) {
		UserDefaults.preferredPeripheralId = peripheral.identifier.uuidString

		isConnecting = false
		isConnected = true
		timeoutTimer?.invalidate()
		timeoutCount = 0
		lastConnectionError = ""

		guard
			let device = devices.first(where: { device in
				device.peripheral.identifier == peripheral.identifier
			})
		else {
			lastConnectionError = "Bluetooth connection error, please try again."

			disconnectDevice()
			return
		}

		device.peripheral.delegate = self
		currentDevice.set(device: device)

		peripheral.discoverServices(
			[BluetoothUUID.meshtasticService]
		)

		devicesDelegate?.onDeviceConnected(name: peripheral.name)

		Logger.services.info(
			"Connected to \(peripheral.name ?? peripheral.identifier.uuidString)"
		)
	}

	func centralManager(
		_ central: CBCentralManager,
		didFailToConnect peripheral: CBPeripheral,
		error: Error?
	) {
		cancelPeripheralConnection()

		Logger.services.error(
			"Connection to \(peripheral.name ?? peripheral.identifier.uuidString) failed: \(error.debugDescription)"
		)
	}

	func centralManager(
		_ central: CBCentralManager,
		didDisconnectPeripheral peripheral: CBPeripheral,
		error: Error?
	) {
		currentDevice.clear()

		isConnecting = false
		isConnected = false
		isSubscribed = false

		let manager = LocalNotificationManager()

		if let error {
			// https://developer.apple.com/documentation/corebluetooth/cberror/code
			switch (error as NSError).code {
			case 6:
				lastConnectionError = "Connection timed out. Will connect back soon."

			case 7:
				if UserDefaults.preferredPeripheralId == peripheral.identifier.uuidString {
					manager.notifications = [
						Notification(
							id: peripheral.identifier.uuidString,
							title: "Radio Disconnected",
							subtitle: "\(peripheral.name ?? peripheral.identifier.uuidString)",
							content: error.localizedDescription,
							target: "bluetooth",
							path: "meshtastic:///bluetooth"
						)
					]
					manager.schedule()
				}

				lastConnectionError = "Node was disconnected. Check if it's turned on."

			case 14:
				lastConnectionError = "Pairing was cancelled. Please try to pair the node again."

			default:
				if UserDefaults.preferredPeripheralId == peripheral.identifier.uuidString {
					manager.notifications = [
						Notification(
							id: (peripheral.identifier.uuidString),
							title: "Radio Disconnected",
							subtitle: "\(peripheral.name ?? peripheral.identifier.uuidString)",
							content: error.localizedDescription,
							target: "bluetooth",
							path: "meshtastic:///bluetooth"
						)
					]
					manager.schedule()
				}

				lastConnectionError = error.localizedDescription
			}
		}
	}
}
