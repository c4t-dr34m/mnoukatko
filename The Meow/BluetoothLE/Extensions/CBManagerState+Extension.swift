/*
The Meow - the Meshtastic® client

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

extension CBManagerState {
	var name: String {
		switch self {
		case .unknown:
			return "Unknown"

		case .resetting:
			return "Resetting"

		case .unsupported:
			return "Unsupported"

		case .unauthorized:
			return "Unauthorized"

		case .poweredOff:
			return "Powered Off"

		case .poweredOn:
			return "Powered On"

		default:
			return "Unwknow state: \(self.rawValue)"
		}
	}
}
