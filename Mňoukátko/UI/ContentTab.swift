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

enum ContentTab: Hashable {
	case messages
	case nodes
	case map
	case options

	init(from navigation: Navigation) {
		switch navigation {
		case .messages:
			self = .messages

		case .nodes:
			self = .nodes

		case .map:
			self = .map

		case .options, .connection:
			self = .options
		}
	}
}
