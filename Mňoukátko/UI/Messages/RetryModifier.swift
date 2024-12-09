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

struct RetryModifier: ViewModifier {
	let message: MessageEntity
	let destination: MessageDestination

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleActions: BLEActions
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@State
	private var isShowingConfirmation = false

	func body(content: Self.Content) -> some View {
		Button {
			isShowingConfirmation = true
		} label: {
			content
		}
		.confirmationDialog(
			"This message was likely not delivered.",
			isPresented: $isShowingConfirmation,
			titleVisibility: .visible
		) {
			Button("Try again") {
				guard connectedDevice.getConnectedDevice() != nil else {
					return
				}

				context.delete(message)
				try? context.save()

				if
					bleActions.sendMessage(
						message: message.messagePayload ?? "",
						toUserNum: message.toUser?.num ?? 0,
						channel: message.channel,
						isEmoji: message.isEmoji,
						replyID: message.replyID
					)
				{
					switch destination {
					case let .user(user):
						context.refresh(user, mergeChanges: true)

					case let .channel(channel):
						context.refresh(channel, mergeChanges: true)
					}
				}
			}

			Button("Cancel", role: .cancel) {}
		}
	}
}

extension View {
	func withRetry(message: MessageEntity, destination: MessageDestination) -> some View {
		modifier(
			RetryModifier(message: message, destination: destination)
		)
	}
}
