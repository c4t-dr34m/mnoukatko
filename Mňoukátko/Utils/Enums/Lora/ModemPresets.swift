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
import Foundation
import MeshtasticProtobufs

enum ModemPresets: Int, CaseIterable, Identifiable {
	case longFast = 0
	case longSlow = 1
	case longModerate = 7
	case vLongSlow = 2
	case medSlow = 3
	case medFast = 4
	case shortSlow = 5
	case shortFast = 6

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .longFast:
			return "Long Range - Fast"

		case .longSlow:
			return "Long Range - Slow"

		case .longModerate:
			return "Long Range - Moderate"

		case .vLongSlow:
			return "Very Long Range - Slow"

		case .medSlow:
			return "Medium Range - Slow"

		case .medFast:
			return "Medium Range - Fast"

		case .shortSlow:
			return "Short Range - Slow"

		case .shortFast:
			return "Short Range - Fast"
		}
	}

	var name: String {
		switch self {
		case .longFast:
			return "LongFast"

		case .longSlow:
			return "LongSlow"

		case .longModerate:
			return "LongModerate"

		case .vLongSlow:
			return "VLongFast"

		case .medSlow:
			return "MediumSlow"

		case .medFast:
			return "MediumFast"

		case .shortSlow:
			return "ShortSlow"

		case .shortFast:
			return "ShortFast"
		}
	}

	func snrLimit() -> Float {
		switch self {
		case .longFast:
			return -17.5

		case .longSlow:
			return -7.5

		case .longModerate:
			return -17.5

		case .vLongSlow:
			return -20

		case .medSlow:
			return -15

		case .medFast:
			return -12.5

		case .shortSlow:
			return -10

		case .shortFast:
			return -7.5
		}
	}

	func protoEnumValue() -> Config.LoRaConfig.ModemPreset {
		switch self {
		case .longFast:
			return Config.LoRaConfig.ModemPreset.longFast

		case .longSlow:
			return Config.LoRaConfig.ModemPreset.longSlow

		case .longModerate:
			return Config.LoRaConfig.ModemPreset.longModerate

		case .vLongSlow:
			return Config.LoRaConfig.ModemPreset.veryLongSlow

		case .medSlow:
			return Config.LoRaConfig.ModemPreset.mediumSlow

		case .medFast:
			return Config.LoRaConfig.ModemPreset.mediumFast

		case .shortSlow:
			return Config.LoRaConfig.ModemPreset.shortSlow

		case .shortFast:
			return Config.LoRaConfig.ModemPreset.shortFast
		}
	}
}
