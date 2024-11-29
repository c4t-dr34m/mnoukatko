import Combine
import OSLog
import SwiftUI

final class AppState: ObservableObject {
	static let shared = AppState()

	@Published
	var navigation: Navigation? {
		didSet {
			guard let navigation else {
				return
			}

			tabSelection = ContentTab(from: navigation)
		}
	}
	@Published
	var tabSelection: ContentTab = .nodes
	@Published
	var unreadDirectMessages = 0 {
		didSet {
			setNotificationBadge()
		}
	}
	@Published
	var unreadChannelMessages = 0 {
		didSet {
			setNotificationBadge()
		}
	}
	@Published
	var firmwareVersion = "0.0.0"

	private func setNotificationBadge() {
		UNUserNotificationCenter.current().setBadgeCount(unreadDirectMessages + unreadChannelMessages)
	}
}
