/*
Mňoukátko - the Meshtastic® client

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
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct TextMessageField: View {
	let destination: MessageDestination
	let onSubmit: () -> Void

	private let maxBytes = 228

	@Binding
	var replyMessageId: Int64
	@FocusState.Binding
	var isFocused: Bool

	@EnvironmentObject
	private var bleActions: BLEActions
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@State
	private var typingMessage = ""
	@State
	private var sendPositionWithMessage = false // TODO: actually use this
	@State
	private var totalBytes = 0

	private var remainingCharacters: Int {
		maxBytes - totalBytes
	}
	private var backgroundColor: Color {
		colorScheme == .dark ? .black : .white
	}

	var body: some View {
		HStack(alignment: .bottom, spacing: 8) {
			ZStack(alignment: .bottom) {
				TextField("", text: $typingMessage, axis: .vertical)
					.font(.body)
					.multilineTextAlignment(.leading)
					.keyboardType(.default)
					.keyboardShortcut(.defaultAction)
					.padding(.horizontal, 16)
					.padding(.vertical, 8)
					.overlay(
						RoundedRectangle(cornerRadius: 16)
							.stroke(.tertiary, lineWidth: 2)
					)
					.clipShape(
						RoundedRectangle(cornerRadius: 16)
					)
					.frame(minHeight: 32)
					.focused($isFocused, equals: true)
					.onChange(of: typingMessage, initial: true) {
						totalBytes = typingMessage.trimmingCharacters(in: .whitespacesAndNewlines).count
					}
					.onSubmit {
						if typingMessage.isEmpty || totalBytes > maxBytes {
							return
						}

						sendMessage()
					}

				HStack(alignment: .bottom) {
					Spacer()

					Text(String(remainingCharacters))
						.font(.system(size: 8, design: .rounded))
						.fontWeight(remainingCharacters < 24 ? .bold : .regular)
						.foregroundColor(remainingCharacters < 24 ? .red : .gray)
						.frame(alignment: .bottomTrailing)
						.padding(.trailing, 10)
						.padding(.bottom, 4)
				}
			}

			Button(action: sendMessage) {
				Image(systemName: "paperplane.fill")
					.resizable()
					.scaledToFit()
					.foregroundColor(.accentColor)
					.padding(.all, 4)
					.frame(width: 32, height: 32)
			}
			.disabled(typingMessage.isEmpty || remainingCharacters <= 0)
		}
		.padding(.all, 2)
		.background(backgroundColor)
		.onTapGesture {
			isFocused = true
		}
	}

	private func sendMessage() {
		let messageSent = bleActions.sendMessage(
			message: typingMessage.trimmingCharacters(in: .whitespacesAndNewlines),
			toUserNum: destination.userNum,
			channel: destination.channelNum,
			isEmoji: typingMessage.isEmoji(),
			replyID: replyMessageId
		)

		if messageSent {
			typingMessage = ""
			isFocused = false
			replyMessageId = 0

			onSubmit()

			if sendPositionWithMessage {
				bleActions.sendPosition(
					channel: destination.channelNum,
					destNum: destination.positionDestNum,
					wantResponse: destination.wantPositionResponse
				)
			}
		}
	}
}

private extension MessageDestination {
	var positionDestNum: Int64 {
		switch self {
		case let .user(user):
			return user.num

		case .channel:
			return Int64(Constants.maximumNodeNum)
		}
	}

	var wantPositionResponse: Bool {
		switch self {
		case .user:
			return true

		case .channel:
			return false
		}
	}
}
