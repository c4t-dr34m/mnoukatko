/*
Meow - the Meshtastic® client

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
import OSLog
import SwiftUI

final class LocalNotificationManager {
	private let semaphore = DispatchSemaphore(value: 1)

	private var notifications = [Notification]()

	func queue(
		notification: Notification,
		delay: TimeInterval = 5,
		silent: Bool = false,
		removeExisting: Bool = false
	) {
		semaphore.wait()
		notifications.removeAll(where: { queuedNotification in
			queuedNotification.id == notification.id
		})
		notifications.append(notification)
		Logger.notification.debug("New notification qeueued: \(notification.id) | \(notification.title)")
		semaphore.signal()

		process(delay: delay, silent: silent, removeExisting: removeExisting)
	}

	func remove(with id: String) {
		semaphore.wait()
		notifications.removeAll(where: { queuedNotification in
			queuedNotification.id == id
		})
		semaphore.signal()

		let center = UNUserNotificationCenter.current()
		center.removeDeliveredNotifications(withIdentifiers: [id])

		Logger.notification.debug("Notifications cancelled: \(id)")
	}

	private func process(
		delay: TimeInterval = 5,
		silent: Bool = false,
		removeExisting: Bool = false
	) {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			switch settings.authorizationStatus {
			case .notDetermined:
				self.requestAuthorization(delay: delay, silent: silent, removeExisting: removeExisting)

			case .authorized, .provisional:
				self.scheduleNotifications(delay: delay, silent: silent, removeExisting: removeExisting)

			default:
				break // Do nothing
			}
		}
	}

	private func requestAuthorization(
		delay: TimeInterval = 5,
		silent: Bool = false,
		removeExisting: Bool = false
	) {
		UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		) { granted, error in
			guard granted, error == nil else {
				return
			}

			self.scheduleNotifications(delay: delay, silent: silent, removeExisting: removeExisting)
		}
	}

	private func scheduleNotifications(
		delay: TimeInterval = 5,
		silent: Bool = false,
		removeExisting: Bool = false
	) {
		while !notifications.isEmpty {
			semaphore.wait()
			let notification = notifications.removeFirst()
			semaphore.signal()

			let content = UNMutableNotificationContent()
			content.title = notification.title
			if let subtitle = notification.subtitle {
				content.subtitle = subtitle
			}
			if let body = notification.body {
				content.body = body
			}
			content.sound = silent ? .none : .default
			content.interruptionLevel = silent ? .passive : .active

			if let path = notification.path {
				content.userInfo["path"] = path.absoluteString
			}

			let trigger = UNTimeIntervalNotificationTrigger(
				timeInterval: delay,
				repeats: false
			)
			let request = UNNotificationRequest(
				identifier: notification.id,
				content: content,
				trigger: trigger
			)

			let center = UNUserNotificationCenter.current()
			if removeExisting {
				center.removeDeliveredNotifications(withIdentifiers: [notification.id])
			}
			center.add(request)

			Logger.notification.debug("Notification may be scheduled: \(notification.id) | \(notification.title)")
		}
	}
}
