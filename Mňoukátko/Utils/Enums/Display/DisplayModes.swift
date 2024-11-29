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
import Foundation
import MeshtasticProtobufs

// Default of 0 is auto
enum DisplayModes: Int, CaseIterable, Identifiable {
	case defaultMode = 0
	case twoColor = 1
	case inverted = 2
	case color = 3

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .defaultMode:
			return "Default 128x64 screen layout"

		case .twoColor:
			return "Optimized for 2-color display"

		case .inverted:
			return "Inverted top bar; 2-color display"

		case .color:
			return "Full color display"
		}
	}

	func protoEnumValue() -> Config.DisplayConfig.DisplayMode {
		switch self {
		case .defaultMode:
			return Config.DisplayConfig.DisplayMode.default

		case .twoColor:
			return Config.DisplayConfig.DisplayMode.twocolor

		case .inverted:
			return Config.DisplayConfig.DisplayMode.inverted

		case .color:
			return Config.DisplayConfig.DisplayMode.color
		}
	}
}
