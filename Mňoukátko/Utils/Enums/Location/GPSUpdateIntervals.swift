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

enum GPSUpdateIntervals: Int, CaseIterable, Identifiable {
	case thirtySeconds = 30
	case oneMinute = 60
	case twoMinutes = 120
	case fiveMinutes = 300
	case tenMinutes = 600
	case fifteenMinutes = 900
	case thirtyMinutes = 1800
	case oneHour = 3600
	case sixHours = 21600
	case twelveHours = 43200
	case twentyFourHours = 86400
	case maxInt32 = 2147483647

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .thirtySeconds:
			return "30s"

		case .oneMinute:
			return "1m"

		case .twoMinutes:
			return "2m"

		case .fiveMinutes:
			return "5m"

		case .tenMinutes:
			return "10m"

		case .fifteenMinutes:
			return "15m"

		case .thirtyMinutes:
			return "30m"

		case .oneHour:
			return "1h"

		case .sixHours:
			return "6h"

		case .twelveHours:
			return "12h"

		case .twentyFourHours:
			return "24h"

		case .maxInt32:
			return "On Boot"
		}
	}
}
