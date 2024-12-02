/*
Mňoukátko - a Meshtastic® client

Copyright © 2022 Garth Vander Houwen
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
import Firebase
import OSLog
import SwiftUI

final class MňoukátkoDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		FirebaseApp.configure()

		Analytics.setAnalyticsCollectionEnabled(true)
		Analytics.logEvent(AnalyticEvents.appLaunch.id, parameters: nil)

		// Default User Default Values
		UserDefaults.standard.register(defaults: ["meshMapShowNodeHistory": true])

		UNUserNotificationCenter.current().delegate = self

		return true
	}

	func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplication.OpenURLOptionsKey: Any] = [:]
	) -> Bool {
		if url.scheme == AppConstants.scheme {
			AppState.shared.navigation = Navigation(from: url)

			return true
		}

		return false
	}

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		willPresent notification: UNNotification,
		withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
	) {
		completionHandler([.list, .banner, .sound])
	}

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		didReceive response: UNNotificationResponse,
		withCompletionHandler completionHandler: @escaping () -> Void
	) {
		let userInfo = response.notification.request.content.userInfo
		if
			let path = userInfo["path"] as? String,
			let url = URL(string: path)
		{
			AppState.shared.navigation = Navigation(from: url)
		}

		completionHandler()
	}
}
