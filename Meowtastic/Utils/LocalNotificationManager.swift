import Foundation
import OSLog
import SwiftUI

final class LocalNotificationManager {
	var notifications = [Notification]()

	func schedule(removeExisting: Bool = false) {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			switch settings.authorizationStatus {
			case .notDetermined:
				self.requestAuthorization(removeExisting: removeExisting)

			case .authorized, .provisional:
				self.scheduleNotifications(removeExisting: removeExisting)

			default:
				break // Do nothing
			}
		}
	}

	private func requestAuthorization(removeExisting: Bool = false) {
		UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		) { granted, error in
			guard granted, error == nil else {
				return
			}

			self.scheduleNotifications(removeExisting: removeExisting)
		}
	}

	private func scheduleNotifications(removeExisting: Bool = false) {
		for notification in notifications {
			let content = UNMutableNotificationContent()

			content.title = notification.title
			if let subtitle = notification.subtitle {
				content.subtitle = subtitle
			}
			if let body = notification.body {
				content.body = body
			}
			content.sound = .default
			content.interruptionLevel = .passive

			if let target = notification.target {
				content.userInfo["target"] = target
			}
			if let path = notification.path {
				content.userInfo["path"] = path
			}

			let trigger = UNTimeIntervalNotificationTrigger(
				timeInterval: 1,
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
		}
	}
}
