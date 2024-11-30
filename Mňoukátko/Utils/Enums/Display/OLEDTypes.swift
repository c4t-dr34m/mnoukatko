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

// Default of 0 is auto
enum OLEDTypes: Int, CaseIterable, Identifiable {
	case auto = 0
	case ssd1306 = 1
	case sh1106 = 2
	case sh1107 = 3

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .auto:
			return "Auto"

		case .ssd1306:
			return "SSD 1306"

		case .sh1106:
			return "SH 1106"

		case .sh1107:
			return "SH 1107"
		}
	}

	func protoEnumValue() -> Config.DisplayConfig.OledType {
		switch self {
		case .auto:
			return Config.DisplayConfig.OledType.oledAuto

		case .ssd1306:
			return Config.DisplayConfig.OledType.oledSsd1306

		case .sh1106:
			return Config.DisplayConfig.OledType.oledSh1106

		case .sh1107:
			return Config.DisplayConfig.OledType.oledSh1107
		}
	}
}
