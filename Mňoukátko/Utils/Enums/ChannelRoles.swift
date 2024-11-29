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

// Default of 0 is Client
enum ChannelRoles: Int, CaseIterable, Identifiable {
	case disabled = 0
	case primary = 1
	case secondary = 2

	var id: Int {
		self.rawValue
	}

	var description: String {
		switch self {
		case .disabled:
			return "channel.role.disabled".localized

		case .primary:
			return "channel.role.primary".localized

		case .secondary:
			return "channel.role.secondary".localized
		}
	}

	func protoEnumValue() -> Channel.Role {
		switch self {
		case .disabled:
			return Channel.Role.disabled

		case .primary:
			return Channel.Role.primary

		case .secondary:
			return Channel.Role.secondary
		}
	}
}
