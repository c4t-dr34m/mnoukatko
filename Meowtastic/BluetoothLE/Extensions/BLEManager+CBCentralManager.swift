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
			peripheral: peripheral,
			id: peripheral.identifier.uuidString,
			num: 0,
			name: name ?? "Unknown",
			shortName: "?",
			longName: name ?? "Unknown",
			firmwareVersion: "Unknown",
			rssi: RSSI.intValue,
			lastUpdate: Date.now
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
			Logger.services.error("Can't find device it just connected to")
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
			"Connected to \(peripheral.name ?? peripheral.identifier.uuidString) failed: \(error.debugDescription)"
		)
	}

	func centralManager(
		_ central: CBCentralManager,
		didDisconnectPeripheral peripheral: CBPeripheral,
		error: Error?
	) {
		Logger.services.debug(
			"Disconnected from \(peripheral.name ?? peripheral.identifier.uuidString)"
		)

		currentDevice.clear()

		isConnecting = false
		isConnected = false
		isSubscribed = false

		if let error {
			// https://developer.apple.com/documentation/corebluetooth/cberror/code
			switch (error as NSError).code {
			case 6:
				lastConnectionError = "Connection timed out. Will connect back soon."

			case 7:
				if UserDefaults.preferredPeripheralId == peripheral.identifier.uuidString {
					notificationManager.queue(
						notification: Notification(
							id: peripheral.identifier.uuidString,
							title: "Radio Disconnected",
							subtitle: "\(peripheral.name ?? peripheral.identifier.uuidString)",
							body: error.localizedDescription,
							path: URL(string: "\(AppConstants.meowtasticScheme):///connection")
						)
					)
				}

				lastConnectionError = "Node was disconnected. Check if it's turned on."

			case 14:
				lastConnectionError = "Pairing was cancelled. Please try to pair the node again."

			default:
				if UserDefaults.preferredPeripheralId == peripheral.identifier.uuidString {
					notificationManager.queue(
						notification: Notification(
							id: (peripheral.identifier.uuidString),
							title: "Radio Disconnected",
							subtitle: "\(peripheral.name ?? peripheral.identifier.uuidString)",
							body: error.localizedDescription,
							path: URL(string: "\(AppConstants.meowtasticScheme):///connection")
						)
					)
				}

				lastConnectionError = error.localizedDescription
			}
		}
	}
}
