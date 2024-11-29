import OSLog
import SwiftUI

struct RetryButton: View {
	let message: MessageEntity
	let destination: MessageDestination

	@State
	var isShowingConfirmation = false

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleActions: BLEActions
	@EnvironmentObject
	private var connectedDevice: CurrentDevice

	var body: some View {
		Button {
			isShowingConfirmation = true
		} label: {
			Image(systemName: "exclamationmark.circle")
				.foregroundColor(.gray)
				.frame(height: 30)
				.padding(.top, 5)
		}
		.confirmationDialog(
			"This message was likely not delivered.",
			isPresented: $isShowingConfirmation,
			titleVisibility: .visible
		) {
			Button("Try Again") {
				guard connectedDevice.getConnectedDevice() != nil else {
					return
				}

				let messageID = message.messageId
				let payload = message.messagePayload ?? ""
				let userNum = message.toUser?.num ?? 0
				let channel = message.channel
				let isEmoji = message.isEmoji
				let replyID = message.replyID
				context.delete(message)

				do {
					try context.save()
				}
				catch {
					Logger.data.error("Failed to delete message \(messageID): \(error.localizedDescription)")
				}

				if !bleActions.sendMessage(
					message: payload,
					toUserNum: userNum,
					channel: channel,
					isEmoji: isEmoji,
					replyID: replyID
				) {
					// Best effort, unlikely since we already checked BLE state
					Logger.services.warning("Failed to resend message \(messageID)")
				}
				else {
					switch destination {
					case .user:
						break

					case let .channel(channel):
						// We must refresh the channel to trigger a view update since its relationship
						// to messages is via a weak fetched property which is not updated by
						// `bleManager.sendMessage` unlike the user entity.
						context.refresh(channel, mergeChanges: true)
					}
				}
			}
			Button("Cancel", role: .cancel) {}
		}
	}
}
