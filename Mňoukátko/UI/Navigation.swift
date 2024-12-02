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

enum Navigation: Hashable {
	case messages(channel: Int32? = nil, user: Int64? = nil, id: Int64? = nil)
	case nodes(num: Int64? = nil)
	case map
	case options
	case connection // Options → Connection

	// swiftlint:disable:next cyclomatic_complexity
	init(from url: URL) {
		guard url.scheme == AppConstants.scheme else {
			self = .nodes()
			return
		}

		let path = url.path()
		let params = url.queryParameters

		switch path {
		case "/messages":
			if let params {
				let channel: Int32?
				let user: Int64?
				let msgId: Int64?

				if let ch = params["channel"] {
					channel = Int32(ch)
				}
				else {
					channel = nil
				}

				if let us = params["user"] {
					user = Int64(us)
				}
				else {
					user = nil
				}

				if let id = params["id"] {
					msgId = Int64(id)
				}
				else {
					msgId = nil
				}

				self = .messages(channel: channel, user: user, id: msgId)
			}
			else {
				self = .messages()
			}

		case "/nodes":
			if let params, let num = params["num"] {
				self = .nodes(num: Int64(num))
			}
			else {
				self = .nodes()
			}

		case "/map":
			self = .map

		case "/options":
			self = .options

		case "/connection":
			self = .connection

		default:
			self = .nodes()
		}
	}
}
