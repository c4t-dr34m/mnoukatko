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
import SwiftUI

struct MessageListItem: View {
	var message: MessageEntity
	var originalMessage: MessageEntity?
	var onMessageRead: (MessageEntity) -> Void
	var onReply: () -> Void
	var destination: MessageDestination?

	@Binding
	var replyMessageId: Int64

	private let detailInfoTextFont = Font.system(size: 14, weight: .regular, design: .rounded)

	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@AppStorage("preferredPeripheralNum")
	private var preferredPeripheralNum = -1
	@State
	private var nodeDetail: NodeInfoEntity?

	@ViewBuilder
	var body: some View {
		let isCurrentUser = isCurrentUser(message: message, preferredNum: preferredPeripheralNum)

		HStack(alignment: isCurrentUser ? .bottom : .top, spacing: 8) {
			leadingAvatar(for: message)
			content(for: message)
			trailingAvatar(for: message)
		}
		.frame(maxWidth: .infinity)
		.onAppear {
			onMessageRead(message)
		}
		.sheet(item: $nodeDetail) { node in
			NodeDetail(node: node, isInSheet: true)
				.presentationDragIndicator(.visible)
				.presentationDetents([.medium])
		}
	}

	@ViewBuilder
	private func leadingAvatar(for message: MessageEntity) -> some View {
		let isCurrentUser = isCurrentUser(message: message, preferredNum: preferredPeripheralNum)

		if isCurrentUser {
			Spacer()
		}
		else {
			VStack(alignment: .center) {
				if let node = message.fromUser?.userNode {
					AvatarNode(
						node,
						ignoreOffline: true,
						showLastHeard: true,
						size: 64,
						corners: isCurrentUser ? (true, true, false, true) : nil
					)
				}
				else {
					AvatarAbstract(
						color: .gray,
						size: 64,
						corners: isCurrentUser ? (true, true, false, true) : nil
					)
				}
			}
			.frame(width: 64)
			.onTapGesture {
				if let sourceNode = message.fromUser?.userNode {
					nodeDetail = sourceNode
				}
			}
		}
	}

	@ViewBuilder
	private func trailingAvatar(for message: MessageEntity) -> some View {
		let isCurrentUser = isCurrentUser(message: message, preferredNum: preferredPeripheralNum)

		if isCurrentUser {
			if let node = message.fromUser?.userNode {
				AvatarNode(
					node,
					ignoreOffline: true,
					size: 64
				)
			}
			else {
				AvatarAbstract(
					size: 64
				)
			}
		}
		else {
			Spacer()
		}
	}

	@ViewBuilder
	private func content(for message: MessageEntity) -> some View {
		let isCurrentUser = isCurrentUser(message: message, preferredNum: preferredPeripheralNum)

		VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
			if !isCurrentUser {
				HStack(spacing: 4) {
					if message.fromUser != nil {
						Image(systemName: "person")
							.font(detailInfoTextFont)
							.foregroundColor(.gray)

						Text(getSenderName(message: message))
							.font(detailInfoTextFont)
							.lineLimit(1)
							.foregroundColor(.gray)

						if let node = message.fromUser?.userNode, let nodeNum = connectedDevice.device?.num {
							NodeIconsCompactView(
								connectedNode: nodeNum,
								node: node
							)
						}
					}
					else {
						Image(systemName: "person.fill.questionmark")
							.font(detailInfoTextFont)
							.foregroundColor(.gray)
					}
				}
			}
			else {
				EmptyView()
			}

			if let destination {
				HStack(spacing: 0) {
					MessageContentView(
						message: message,
						originalMessage: originalMessage,
						tapBackDestination: destination,
						isCurrentUser: isCurrentUser
					) {
						replyMessageId = message.messageId
						onReply()
					}

					if isCurrentUser && message.canRetry {
						RetryButton(message: message, destination: destination)
					}
				}
			}
		}
	}

	private func isCurrentUser(message: MessageEntity, preferredNum: Int) -> Bool {
		Int64(preferredNum) == message.fromUser?.num
	}

	private func getSenderName(message: MessageEntity, short: Bool = false) -> String {
		let shortName = message.fromUser?.shortName
		let longName = message.fromUser?.longName

		if short {
			if let shortName {
				return shortName
			}
			else {
				return ""
			}
		}
		else {
			if let longName {
				return longName
			}
			else {
				return "Unknown Name"
			}
		}
	}
}
