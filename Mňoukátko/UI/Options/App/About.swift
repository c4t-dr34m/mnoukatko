/*
Mňoukátko - a Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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
import FirebaseAnalytics
import StoreKit
import SwiftUI

struct About: View {
	private let locale = Locale.current

	@ViewBuilder
	var body: some View {
		List {
			Section(header: Text("This Application")) {
				Button("Rate Mňoukátko") {
					if let scene = UIApplication.shared.connectedScenes.first(where: {
						$0.activationState == .foregroundActive
					}) as? UIWindowScene {
						SKStoreReviewController.requestReview(in: scene)
					}
				}
				.font(.body)

				Link(
					"Roadmap",
					// swiftlint:disable force_unwrapping
					destination: URL(
						string: "https://c4tdr34m.notion.site/3a35d93cc13e4c62ba46dea470e4580d?v=e47eeeaf93b9491ab95436c59e0f6829&pvs=74"
					)!
					// swiftlint:enable force_unwrapping
				)
				.font(.body)

				Link(
					"Source code",
					// swiftlint:disable:next force_unwrapping
					destination: URL(string: "https://github.com/c4t-dr34m/mnoukatko")!
				)
				.font(.body)

				if
					let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
					let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
				{
					Text("Version: \(version):\(build)")
				}
			}

			Section {
				VStack(alignment: .leading, spacing: 8) {
					Text("Mňoukátko — the Meshtastic® client")
						.font(.body)
						.padding(.bottom, 8)

					Text("Copyright © 2021-2024 Garth Vander Houwen")
						.font(.body)

					Text("Copyright © 2024 Radovan Paška")
						.font(.body)
						.padding(.bottom, 8)

					Text("This program comes with ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to redistribute it under certain conditions; visit GitHub repository (see \"Source code\" above) to learn more.")
						.font(.body)
				}

				VStack(alignment: .leading, spacing: 8) {
					Text(
						"Meshtastic® is a registered trademark of Meshtastic LLC. Meshtastic LLC is not associated with Mňoukátko."
					)
					.font(.footnote)
				}
			}
		}
		.navigationTitle("About")
		.navigationBarTitleDisplayMode(.inline)
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsAbout.id, parameters: nil)
		}
	}
}
