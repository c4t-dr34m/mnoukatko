/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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
import CoreData
import SwiftUI

struct ExchangePositionsButton: View {
	var node: NodeInfoEntity

	@EnvironmentObject
	private var bleActions: BLEActions
	@State
	private var isPresentingPositionSentAlert = false

	var body: some View {
		Button {
			isPresentingPositionSentAlert = bleActions.sendPosition(
				channel: node.channel,
				destNum: node.num,
				wantResponse: true
			)
		} label: {
			Label {
				Text("Exchange Positions")
			} icon: {
				Image(systemName: "arrow.triangle.2.circlepath")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}
		}.alert(
			"Position Sent",
			isPresented: $isPresentingPositionSentAlert
		) {
			Button("OK") { }
				.keyboardShortcut(.defaultAction)
		} message: {
			Text("Your position has been sent with a request for a response with their position.")
		}
	}
}
