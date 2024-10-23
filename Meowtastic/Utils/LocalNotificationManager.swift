import Foundation
import OSLog
import SwiftUI

final class LocalNotificationManager {
	private let semaphore = DispatchSemaphore(value: 1)

	private var notifications = [Notification]()

	func queue(
		notification: Notification,
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

		process(silent: silent, removeExisting: removeExisting)
	}

	private func process(
		silent: Bool = false,
		removeExisting: Bool = false
	) {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			switch settings.authorizationStatus {
			case .notDetermined:
				self.requestAuthorization(silent: silent, removeExisting: removeExisting)

			case .authorized, .provisional:
				self.scheduleNotifications(silent: silent, removeExisting: removeExisting)

			default:
				break // Do nothing
			}
		}
	}

	private func requestAuthorization(
		silent: Bool = false,
		removeExisting: Bool = false
	) {
		UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		) { granted, error in
			guard granted, error == nil else {
				return
			}

			self.scheduleNotifications(silent: silent, removeExisting: removeExisting)
		}
	}

	private func scheduleNotifications(
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

			if let target = notification.target {
				content.userInfo["target"] = target
			}
			if let path = notification.path {
				content.userInfo["path"] = path
			}

			let trigger = UNTimeIntervalNotificationTrigger(
				timeInterval: 5,
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

			Logger.notification.debug("Notification scheduled: \(notification.id) | \(notification.title)")
		}
	}
}
