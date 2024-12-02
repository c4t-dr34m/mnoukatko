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

enum Bandwidths: Int, CaseIterable, Identifiable {
	case thirtyOne = 31
	case sixtyTwo = 62
	case oneHundredTwentyFive = 125
	case twoHundredFifty = 250
	case fiveHundred = 500

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .thirtyOne:
			return "31 kHz"

		case .sixtyTwo:
			return "62 kHz"

		case .oneHundredTwentyFive:
			return "125 kHz"

		case .twoHundredFifty:
			return "250 kHz"

		case .fiveHundred:
			return "500 kHz"
		}
	}
}
