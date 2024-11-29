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

// Default of 0 is off
enum ScreenCarouselIntervals: Int, CaseIterable, Identifiable {
	case off = 0
	case fifteenSeconds = 15
	case thirtySeconds = 30
	case oneMinute = 60
	case fiveMinutes = 300
	case tenMinutes = 600
	case fifteenMinutes = 900

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .off:
			return "Off"

		case .fifteenSeconds:
			return "15s"

		case .thirtySeconds:
			return "30s"

		case .oneMinute:
			return "1m"

		case .fiveMinutes:
			return "5m"

		case .tenMinutes:
			return "10m"

		case .fifteenMinutes:
			return "15m"
		}
	}
}
