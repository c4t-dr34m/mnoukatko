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
import SwiftUI

struct InvalidVersion: View {
	@State
	var minimumVersion: String
	@State
	var version: String

	@Environment(\.dismiss)
	private var dismiss

	var body: some View {
		VStack {
			Text("update.firmware")
				.font(.largeTitle)
				.foregroundColor(.accentColor)

			Divider()

			VStack {
				Text("The Meshtastic Apple apps support firmware version \(minimumVersion) and above.")
					.font(.body)
					.padding(.bottom)

				Link(
					"Firmware update docs",
					// swiftlint:disable:next force_unwrapping
					destination: URL(string: "https://meshtastic.org/docs/getting-started/flashing-firmware/")!
				)
				.font(.body)
				.padding()

				Link(
					"Additional help",
					// swiftlint:disable:next force_unwrapping
					destination: URL(string: "https://meshtastic.org/docs/faq")!
				)
				.font(.body)
				.padding()
			}
			.padding()

			Divider()
				.padding(.top)

			VStack {
				Text("🦕 End of life Version 🦖 ☄️")
					.font(.title3)
					.foregroundColor(.accentColor)
					.padding(.bottom)

				Text("Version \(minimumVersion) includes breaking changes to devices and the client apps. Only nodes version \(minimumVersion) and above are supported.")
					.font(.callout)
					.padding([.leading, .trailing, .bottom])

				Link(
					"Version 1.2 End of life (EOL) Info",
					destination: URL(string: "https://meshtastic.org/docs/1.2-End-of-life/")!
				)
				.font(.callout)
			}.padding()
		}
	}
}
