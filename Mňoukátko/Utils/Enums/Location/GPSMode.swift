/*
Mňoukátko - a Meshtastic® client

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

enum GPSMode: Int, CaseIterable, Equatable {
	case enabled = 1
	case disabled = 0
	case notPresent = 2

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .disabled:
			return "Disabled"

		case .enabled:
			return "Enabled"

		case .notPresent:
			return "Not Present"
		}
	}

	func protoEnumValue() -> Config.PositionConfig.GpsMode {
		switch self {
		case .enabled:
			return Config.PositionConfig.GpsMode.enabled

		case .disabled:
			return Config.PositionConfig.GpsMode.disabled

		case .notPresent:
			return Config.PositionConfig.GpsMode.notPresent
		}
	}
}
