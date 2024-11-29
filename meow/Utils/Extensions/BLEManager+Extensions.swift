/*
Meow - the Meshtastic® client

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
