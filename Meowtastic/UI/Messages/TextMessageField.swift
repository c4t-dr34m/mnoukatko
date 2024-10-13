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
					.foregroundColor(.meowOrange)
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
