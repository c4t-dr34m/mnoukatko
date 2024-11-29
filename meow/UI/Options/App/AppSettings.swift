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
import Combine
import FirebaseAnalytics
import Foundation
import MapKit
import OSLog
import SwiftProtobuf
import SwiftUI

struct AppSettings: View {
	private let notificationManager = UNUserNotificationCenter.current()

	@Environment(\.managedObjectContext)
	private var context
	@State
	private var hasNotifications = false
	@State
	private var isPresentingCoreDataResetConfirm = false
	@State
	private var isPresentingDeleteMapTilesConfirm = false
	@State
	private var powerSavingMode = UserDefaults.powerSavingMode
	@State
	private var lowBatteryNotifications = UserDefaults.lowBatteryNotifications
	@State
	private var directMessageNotifications = UserDefaults.directMessageNotifications
	@State
	private var channelMessageNotifications = UserDefaults.channelMessageNotifications
	@State
	private var newNodeNotifications = UserDefaults.newNodeNotifications
	@State
	private var bcgNotification = UserDefaults.bcgNotification
	@State
	private var moreColors = UserDefaults.moreColors

	var body: some View {
		Form {
			Section(header: Text("Power")) {
				VStack(alignment: .leading, spacing: 8) {
					let processInfo = ProcessInfo.processInfo

					Toggle(isOn: $powerSavingMode) {
						Text("Power Saving Mode")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.disabled(processInfo.isLowPowerModeEnabled)
					.onChange(of: powerSavingMode) {
						UserDefaults.powerSavingMode = powerSavingMode
					}

					if powerSavingMode {
						Text("Node will disconnect when app is in background.")
							.font(.callout)
							.foregroundColor(.gray)
					}
					else {
						Text("Node will stay connected as long as iOS allows.")
							.font(.callout)
							.foregroundColor(.gray)
					}
				}
			}

			Section(header: Text("Notifications")) {
				Toggle(isOn: $lowBatteryNotifications) {
					Text("Low Battery")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: lowBatteryNotifications) {
					if !hasNotifications, lowBatteryNotifications {
						authorizeNotifications()
					}

					UserDefaults.lowBatteryNotifications = lowBatteryNotifications
				}

				Toggle(isOn: $directMessageNotifications) {
					Text("New Direct Message")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: directMessageNotifications) {
					if !hasNotifications, directMessageNotifications {
						authorizeNotifications()
					}

					UserDefaults.directMessageNotifications = directMessageNotifications
				}

				Toggle(isOn: $channelMessageNotifications) {
					Text("New Channel Message")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: channelMessageNotifications) {
					if !hasNotifications, channelMessageNotifications {
						authorizeNotifications()
					}

					UserDefaults.channelMessageNotifications = channelMessageNotifications
				}

				Toggle(isOn: $newNodeNotifications) {
					Text("Node Discovered")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: newNodeNotifications) {
					if !hasNotifications, newNodeNotifications {
						authorizeNotifications()
					}

					UserDefaults.newNodeNotifications = newNodeNotifications
				}

				VStack(alignment: .leading, spacing: 8) {
					Toggle(isOn: $bcgNotification) {
						Text("Background Update Summary")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.onChange(of: bcgNotification) {
						if !hasNotifications, bcgNotification {
							authorizeNotifications()
						}

						UserDefaults.bcgNotification = bcgNotification
					}

					Text("Show number of visible nodes when background update finishes. Not very useful, but hey... you can have it.")
						.font(.callout)
						.foregroundColor(.gray)
				}
			}
			.onAppear {
				checkAuthorizations()
			}

			Section(header: Text("Look & Feel")) {
				Toggle(isOn: $moreColors) {
					Text("More Colors")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: moreColors) {
					UserDefaults.moreColors = moreColors
				}
			}

			Section(header: Text("Settings")) {
				Button("Open Settings", systemImage: "gear") {
					if let url = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(url)
					}
				}
			}
		}
		.navigationTitle("App Settings")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsAppSettings.id, parameters: nil)
		}
	}

	private func checkAuthorizations() {
		notificationManager.getNotificationSettings { settings in
			self.hasNotifications = settings.authorizationStatus == .authorized
		}
	}

	private func authorizeNotifications() {
		UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		) { granted, error in
			guard granted, error == nil else {
				return
			}

			checkAuthorizations()
		}
	}
}
