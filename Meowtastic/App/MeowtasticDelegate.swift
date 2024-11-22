import Firebase
import OSLog
import SwiftUI

final class MeowtasticDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
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
		if url.scheme == AppConstants.meowtasticScheme {
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
