/*
Mňoukátko - the Meshtastic® client

Copyright © 2022-2024 Garth Vander Houwen
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
			name: name ?? "Unknown node",
			shortName: "?",
			longName: name ?? "Unknown node",
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
							path: URL(string: "\(AppConstants.scheme):///connection")
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
							path: URL(string: "\(AppConstants.scheme):///connection")
						)
					)
				}

				lastConnectionError = error.localizedDescription
			}
		}
	}
}
