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
import Foundation

enum UpdateIntervals: Int, CaseIterable, Identifiable {
	case tenSeconds = 10
	case thirtySeconds = 30
	case oneMinute = 60
	case fiveMinutes = 300
	case tenMinutes = 600
	case thirtyMinutes = 1800
	case oneHour = 3600
	case threeHours = 10800
	case sixHours = 21600
	case twelveHours = 43200
	case twentyFourHours = 86400
	case fortyeightHours = 172800

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .tenSeconds:
			return "10s"

		case .thirtySeconds:
			return "30s"

		case .oneMinute:
			return "1m"

		case .fiveMinutes:
			return "5m"

		case .tenMinutes:
			return "10m"

		case .thirtyMinutes:
			return "30m"

		case .oneHour:
			return "1h"

		case .threeHours:
			return "3h"

		case .sixHours:
			return "6h"

		case .twelveHours:
			return "12h"

		case .twentyFourHours:
			return "24h"

		case .fortyeightHours:
			return "2d"
		}
	}
}
