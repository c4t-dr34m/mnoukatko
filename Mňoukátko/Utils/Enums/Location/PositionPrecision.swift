/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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
import MapKit
enum PositionPrecision: Int, CaseIterable, Identifiable {
	case two = 2
	case three = 3
	case four = 4
	case five = 5
	case six = 6
	case seven = 7
	case eight = 8
	case nine = 9
	case ten = 10
	case eleven = 11
	case twelve = 12
	case thirteen = 13
	case fourteen = 14
	case fifteen = 15
	case sixteen = 16
	case seventeen = 17
	case eightteen = 18
	case nineteen = 19
	case twenty = 20
	case twentyone = 21
	case twentytwo = 22
	case twentythree = 23
	case twentyfour = 24

	var id: Int {
		rawValue
	}

	var precisionMeters: Double {
		// source of this shit: https://github.com/meshtastic/Meshtastic-Android/issues/893
		switch self {
		case .two:
			return 5976446.981252

		case .three:
			return 2988223.4850600003

		case .four:
			return 1494111.7369640006

		case .five:
			return 747055.8629159998

		case .six:
			return 373527.9258920002

		case .seven:
			return 186763.95738000044

		case .eight:
			return 93381.97312400135

		case .nine:
			return 46690.98099600022

		case .ten:
			return 23345.48493200123

		case .eleven:
			return 11672.736900000944

		case .twelve:
			return 5836.362884000802

		case .thirteen:
			return 2918.1758760007315

		case .fourteen:
			return 1459.0823719999053

		case .fifteen:
			return 729.5356200010741

		case .sixteen:
			return 364.7622440000765

		case .seventeen:
			return 182.37555600115968

		case .eightteen:
			return 91.1822120001193

		case .nineteen:
			return 45.58554000039009

		case .twenty:
			return 22.787204001316468

		case .twentyone:
			return 11.388036000988677

		case .twentytwo:
			return 5.688452000824781

		case .twentythree:
			return 2.8386600007428338

		case .twentyfour:
			return 1.413763999910884
		}
	}
}
