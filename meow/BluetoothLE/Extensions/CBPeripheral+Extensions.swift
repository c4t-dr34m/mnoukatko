/*
Meow - the Meshtastic® client

Copyright (C) 2022-2024 Garth Vander Houwen
Copyright (C) 2024 Radovan Paška

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

extension CBPeripheral {
	func readValue(for characteristic: CBCharacteristic?) {
		guard let characteristic else {
			Logger.app.error("Trying to read value from nil characteristic")
			return
		}

		self.readValue(for: characteristic)
	}

	func writeValue(_ data: Data, for characteristic: CBCharacteristic?, type: CBCharacteristicWriteType) {
		guard let characteristic else {
			Logger.app.error("Trying to write value to nil characteristic")
			return
		}

		writeValue(data, for: characteristic, type: type)
	}
}
