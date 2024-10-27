import Foundation

enum ContentTab: Hashable {
	case messages
	case nodes
	case map
	case options

	// swiftlint:disable:next cyclomatic_complexity
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
