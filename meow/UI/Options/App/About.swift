/*
Meow - the Meshtastic® client

Copyright (C) 2022-2024 Garth Vander Houwen
Copyright (C) 2024 Radovan Paška

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
				Button("Rate Meow") {
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
					destination: URL(string: "https://github.com/c4t-dr34m/meow")!
				)
				.font(.body)

				Text("Version: \(Bundle.main.appVersionLong)/\(Bundle.main.appBuild)")
			}

			Section(header: Text("Credits")) {
				VStack(alignment: .leading, spacing: 8) {
					Link(
						"Meshtastic®",
						// swiftlint:disable:next force_unwrapping
						destination: URL(string: "https://meshtastic.org")!
					)
					.font(.body)

					Text("An open source, off-grid, decentralized, mesh network built to run on affordable, low-power devices. Obviously, this app would be useless without them")
						.font(.body)

					Text(
						"Meshtastic® is a registered trademark of Meshtastic LLC"
					)
					.font(.footnote)
					.foregroundColor(.gray)
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
