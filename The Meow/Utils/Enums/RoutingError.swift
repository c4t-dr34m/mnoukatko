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

enum RoutingError: Int, CaseIterable, Identifiable {
	case none = 0
	case noRoute = 1
	case gotNak = 2
	case timeout = 3
	case noInterface = 4
	case maxRetransmit = 5
	case noChannel = 6
	case tooLarge = 7
	case noResponse = 8
	case dutyCycleLimit = 9
	case badRequest = 32
	case notAuthorized = 33

	var id: Int {
		self.rawValue
	}

	var display: String {
		switch self {
		case .none:
			return "Acknowledged"

		case .noRoute:
			return "No Route"

		case .gotNak:
			return "Got NAK"

		case .timeout:
			return "Timeout"

		case .noInterface:
			return "No Interface"

		case .maxRetransmit:
			return "Max Retransmit"

		case .noChannel:
			return "No Channel"

		case .tooLarge:
			return "Too Large"

		case .noResponse:
			return "No Response"

		case .dutyCycleLimit:
			return "Duty Cycle Limit"

		case .badRequest:
			return "Bad Request"

		case .notAuthorized:
			return "Not Authorized"
		}
	}

	func protoEnumValue() -> Routing.Error {
		switch self {
		case .none:
			return Routing.Error.none

		case .noRoute:
			return Routing.Error.noRoute

		case .gotNak:
			return Routing.Error.gotNak

		case .timeout:
			return Routing.Error.timeout

		case .noInterface:
			return Routing.Error.noInterface

		case .maxRetransmit:
			return Routing.Error.maxRetransmit

		case .noChannel:
			return Routing.Error.noChannel

		case .tooLarge:
			return Routing.Error.tooLarge

		case .noResponse:
			return Routing.Error.noResponse

		case .dutyCycleLimit:
			return Routing.Error.dutyCycleLimit

		case .badRequest:
			return Routing.Error.badRequest

		case .notAuthorized:
			return Routing.Error.notAuthorized
		}
	}
}
