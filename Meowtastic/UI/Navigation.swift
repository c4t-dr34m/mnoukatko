import Foundation

enum Navigation: Hashable {
	case messages(channel: Int32? = nil, user: Int64? = nil, id: Int64? = nil)
	case nodes(num: Int64? = nil)
	case map
	case options
	case connection // Options → Connection

	// swiftlint:disable:next cyclomatic_complexity
	init(from url: URL) {
		guard url.scheme == AppConstants.meowtasticScheme else {
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
