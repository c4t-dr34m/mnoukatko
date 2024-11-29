/*
The Meow - the Meshtastic® client

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

enum GPSFormats: Int, CaseIterable, Identifiable {
	case gpsFormatDec = 0
	case gpsFormatDms = 1
	case gpsFormatUtm = 2
	case gpsFormatMgrs = 3
	case gpsFormatOlc = 4
	case gpsFormatOsgr = 5

	var id: Int {
		self.rawValue
	}

	// TODO: use some user-friendly representation of the format
	var description: String {
		switch self {
		case .gpsFormatDec:
			return "DEC"

		case .gpsFormatDms:
			return "DMS"

		case .gpsFormatUtm:
			return "UTM"

		case .gpsFormatMgrs:
			return "MGRS"

		case .gpsFormatOlc:
			return "OLC"

		case .gpsFormatOsgr:
			return "OSGR"
		}
	}

	func protoEnumValue() -> Config.DisplayConfig.GpsCoordinateFormat {
		switch self {
		case .gpsFormatDec:
			return Config.DisplayConfig.GpsCoordinateFormat.dec

		case .gpsFormatDms:
			return Config.DisplayConfig.GpsCoordinateFormat.dms

		case .gpsFormatUtm:
			return Config.DisplayConfig.GpsCoordinateFormat.utm

		case .gpsFormatMgrs:
			return Config.DisplayConfig.GpsCoordinateFormat.mgrs

		case .gpsFormatOlc:
			return Config.DisplayConfig.GpsCoordinateFormat.olc

		case .gpsFormatOsgr:
			return Config.DisplayConfig.GpsCoordinateFormat.osgr
		}
	}
}
