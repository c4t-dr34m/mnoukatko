/*
Mňoukátko - the Meshtastic® client

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
import Foundation
import MeshtasticProtobufs

enum BluetoothModes: Int, CaseIterable, Identifiable {
	case randomPin = 0
	case fixedPin = 1
	case noPin = 2

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .randomPin:
			return "bluetooth.mode.randompin".localized

		case .fixedPin:
			return "bluetooth.mode.fixedpin".localized

		case .noPin:
			return "bluetooth.mode.nopin".localized
		}
	}

	func protoEnumValue() -> Config.BluetoothConfig.PairingMode {
		switch self {
		case .randomPin:
			return Config.BluetoothConfig.PairingMode.randomPin

		case .fixedPin:
			return Config.BluetoothConfig.PairingMode.fixedPin

		case .noPin:
			return Config.BluetoothConfig.PairingMode.noPin
		}
	}
}
