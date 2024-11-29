import CoreBluetooth
import Foundation

extension BLEManager {
	var isNodeConnected: Bool {
		getConnectedDevice() != nil
	}

	var connectedNodeName: String {
		if let name = getConnectedDevice()?.shortName {
			return name
		}
		else {
			return "N/A"
		}
	}

	func peripheral(
		_ peripheral: CBPeripheral,
		didReadRSSI RSSI: NSNumber,
		error: (any Error)?
	) {
		let uuid = peripheral.identifier.uuidString

		// connected peripheral
		if
			var device = getConnectedDevice(),
			device.id == uuid
		{
			device.rssi = RSSI.intValue

			currentDevice.update(with: device)
		}

		// some other peripheral
		let updatedPeripheralIndex = devices.firstIndex(where: { peripheral in
			peripheral.id == uuid
		})

		guard let updatedPeripheralIndex else {
			return
		}

		let old = devices[updatedPeripheralIndex]
		let new = Device(
			peripheral: old.peripheral,
			id: old.id,
			num: old.num,
			name: old.name,
			shortName: old.shortName,
			longName: old.longName,
			firmwareVersion: old.firmwareVersion,
			rssi: RSSI.intValue,
			lastUpdate: old.lastUpdate
		)
		devices[updatedPeripheralIndex] = new
	}
}
