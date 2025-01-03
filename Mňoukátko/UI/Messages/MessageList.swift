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
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct MessageList: View {
	private let channel: ChannelEntity?
	private let user: UserEntity?
	private let myInfo: MyInfoEntity?
	private let destination: MessageDestination?
	private let debounce = Debounce<() async -> Void>(duration: .milliseconds(500)) { action in
		await action()
	}
	private let notificationManager = LocalNotificationManager()

	@Environment(\.managedObjectContext)
	private var context
	@AppStorage("preferredPeripheralNum")
	private var preferredPeripheralNum = -1
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@StateObject
	private var appState = AppState.shared
	@FocusState
	private var messageFieldFocused: Bool
	@State
	private var replyMessageId: Int64 = 0

	@FetchRequest
	private var messages: FetchedResults<MessageEntity>
	@FetchRequest(sortDescriptors: [])
	private var nodes: FetchedResults<NodeInfoEntity>

	private var firstUnreadMessage: MessageEntity? {
		messages.first(where: { message in
			!message.read
		})
	}
	private var lastMessage: MessageEntity? {
		messages.last
	}
	private var screenTitle: String {
		if let channel {
			if let name = channel.name, !name.isEmpty {
				return name.camelCaseToWords()
			}
			else {
				if channel.role == 1 {
					return "Primary Channel"
				}
				else {
					return "Channel #\(channel.index)"
				}
			}
		}
		else if let user {
			if let name = user.longName {
				return name
			}
			else {
				return "DM"
			}
		}

		return "Messages"
	}

	var body: some View {
		VStack(spacing: 0) {
			ScrollViewReader { scrollView in
				if !messages.isEmpty {
					messageList
						.scrollDismissesKeyboard(.interactively)
						.scrollIndicators(.hidden)
						.onChange(of: messages.last?.messageId, initial: true) {
							scrollToEnd(scrollView)
						}
						.onChange(of: messageFieldFocused) {
							scrollToEnd(scrollView)
						}
				}
				else {
					ContentUnavailableView(
						"No Messages",
						systemImage: channel != nil ? "bubble.left.and.bubble.right" : "bubble"
					)
				}
			}
			.onAppear {
				Analytics.logEvent(
					AnalyticEvents.messageList.id,
					parameters: [
						"kind": channel != nil ? "channel" : "user",
						"messages_in_list": messages.count
					]
				)

				if channel != nil {
					UserDefaults.channelDisplayed = true
				}
			}

			if let destination, connectedDevice.getConnectedDevice() != nil {
				TextMessageField(
					destination: destination,
					onSubmit: {
						if let channel {
							context.refresh(channel, mergeChanges: true)
						}
						else if let user {
							context.refresh(user, mergeChanges: true)
						}
					},
					replyMessageId: $replyMessageId,
					isFocused: $messageFieldFocused
				)
				.frame(alignment: .bottom)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(
					Color(.systemGroupedBackground)
				)
			}
			else {
				EmptyView()
			}
		}
		.toolbar(.hidden, for: .tabBar)
		.navigationTitle(screenTitle)
		.navigationBarTitleDisplayMode(.large)
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
	}

	@ViewBuilder
	private var messageList: some View {
		List {
			ForEach(messages, id: \.messageId) { message in
				MessageListItem(
					message: message,
					originalMessage: getOriginalMessage(for: message),
					onMessageRead: { message in
						var didRead = 0
						for displayedMessage in messages.filter({ msg in
							msg.messageTimestamp <= message.messageTimestamp
						}) where !displayedMessage.read {
							displayedMessage.read.toggle()
							didRead += 1
						}

						guard didRead > 0 else {
							return
						}

						Logger.app.info("Marking \(didRead) message(s) as read")

						debounce.emit {
							await self.saveData()
						}

						if let myInfo {
							appState.unreadChannelMessages = myInfo.unreadMessages
							context.refresh(myInfo, mergeChanges: true)
						}
					},
					onReply: {
						messageFieldFocused = true
					},
					destination: destination,
					replyMessageId: $replyMessageId
				)
				.id(message.messageId)
				.listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
				.listRowSeparator(.hidden)
				.listRowBackground(Color.clear)
				.scrollContentBackground(.hidden)
			}
			.listStyle(.plain)
		}
	}

	init(
		channel: ChannelEntity,
		myInfo: MyInfoEntity?
	) {
		self.channel = channel
		self.user = nil
		self.myInfo = myInfo
		self.destination = .channel(channel)

		let request = MessageEntity.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(key: "messageTimestamp", ascending: true)
		]
		request.predicate = NSPredicate(format: "toUser == nil && channel == %lld", channel.index)

		self._messages = .init(fetchRequest: request)
	}

	init(
		user: UserEntity,
		myInfo: MyInfoEntity?
	) {
		self.channel = nil
		self.user = user
		self.myInfo = myInfo
		self.destination = .user(user)

		let request = MessageEntity.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(key: "messageTimestamp", ascending: true)
		]
		request.predicate = NSPredicate(
			format: "toUser != nil && fromUser != nil && (toUser.num == %lld || fromUser.num == %lld) && admin == false && portNum != 10",
			Int64(user.num),
			Int64(user.num)
		)

		self._messages = .init(fetchRequest: request)
	}

	private func scrollToEnd(_ scrollView: ScrollViewProxy) {
		Task {
			if let firstUnreadMessage {
				scrollView.scrollTo(firstUnreadMessage.messageId, anchor: .bottom)
			}
			else if let lastMessage {
				scrollView.scrollTo(lastMessage.messageId, anchor: .bottom)
			}
		}
	}

	private func getOriginalMessage(for message: MessageEntity) -> MessageEntity? {
		if
			message.replyID > 0,
			let messageReply = messages.first(where: { msg in
				msg.messageId == message.replyID
			}),
			messageReply.messagePayload != nil
		{
			return messageReply
		}

		return nil
	}

	@discardableResult
	func saveData() async -> Bool {
		context.performAndWait {
			guard context.hasChanges else {
				return false
			}

			do {
				try context.save()

				return true
			}
			catch {
				context.rollback()

				return false
			}
		}
	}
}
