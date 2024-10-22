import Combine
import FirebaseAnalytics
import Foundation
import MapKit
import OSLog
import SwiftProtobuf
import SwiftUI

struct AppSettings: View {
	@Environment(\.managedObjectContext)
	private var context
	@State
	private var isPresentingCoreDataResetConfirm = false
	@State
	private var isPresentingDeleteMapTilesConfirm = false
	@State
	private var bcgNotification = UserDefaults.bcgNotification
	@State
	private var moreColors = UserDefaults.moreColors

	var body: some View {
		Form {
			Section(header: Text("Notifications")) {
				VStack(alignment: .leading, spacing: 8) {
					Toggle(isOn: $bcgNotification) {
						Label("Background Update Notification", systemImage: "bell")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.onChange(of: bcgNotification) {
						UserDefaults.bcgNotification = bcgNotification
					}

					Text("Show number of visible nodes when background update finishes. Not very useful, but hey... you can have it.")
						.font(.callout)
						.foregroundColor(.gray)
				}
			}

			Section(header: Text("Look & Feel")) {
				Toggle(isOn: $moreColors) {
					Label("More Colors", systemImage: "paintpalette")
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
}
