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

enum RebroadcastModes: Int, CaseIterable, Identifiable {
	case all = 0
	case allSkipDecoding = 1
	case localOnly = 2
	case knownOnly = 3

	var id: Int {
		self.rawValue
	}

	var name: String {
		switch self {
		case .all:
			return "All"

		case .allSkipDecoding:
			return "All Skip Decoding"

		case .localOnly:
			return "Local Only"

		case .knownOnly:
			return "Known Only"
		}
	}

	var description: String {
		switch self {
		case .all:
			return
"""
Rebroadcast any observed message, if it was on our private channel or from another mesh with the same lora params.
"""

		case .allSkipDecoding:
			return
"""
Same as behavior as ALL but skips packet decoding and simply rebroadcasts them. Only available in Repeater role. Setting this on any other roles will result in ALL behavior.
"""

		case .localOnly:
			return
"""
Ignores observed messages from foreign meshes that are open or those which it cannot decrypt. Only rebroadcasts message on the nodes local primary / secondary channels.
"""

		case .knownOnly:
			return
"""
Ignores observed messages from foreign meshes like Local Only, but takes it step further by also ignoring messages from nodes not already in the node's known list.
"""
		}
	}

	func protoEnumValue() -> Config.DeviceConfig.RebroadcastMode {
		switch self {
		case .all:
			return Config.DeviceConfig.RebroadcastMode.all

		case .allSkipDecoding:
			return Config.DeviceConfig.RebroadcastMode.allSkipDecoding

		case .localOnly:
			return Config.DeviceConfig.RebroadcastMode.localOnly

		case .knownOnly:
			return Config.DeviceConfig.RebroadcastMode.knownOnly
		}
	}
}
