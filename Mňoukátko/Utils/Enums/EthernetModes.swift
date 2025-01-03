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

enum EthernetMode: Int, CaseIterable, Identifiable {
	case dhcp = 0
	case staticip = 1

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .dhcp:
			return "DHCP"

		case .staticip:
			return "Static IP"
		}
	}

	func protoEnumValue() -> Config.NetworkConfig.AddressMode {
		switch self {
		case .dhcp:
			return Config.NetworkConfig.AddressMode.dhcp

		case .staticip:
			return Config.NetworkConfig.AddressMode.static
		}
	}
}
