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
