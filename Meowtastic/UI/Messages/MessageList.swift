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
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
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
		VStack(spacing: 4) {
			ScrollViewReader { scrollView in
				if !messages.isEmpty {
					messageList
						.scrollDismissesKeyboard(.interactively)
						.scrollIndicators(.hidden)
						.onAppear {
							if let channel {
								let id = "notification.id.channel_\(channel.index)"
								notificationManager.remove(with: id)
							}
						}
						.onChange(of: messages.count, initial: true) {
							if let firstUnreadMessage {
								scrollView.scrollTo(firstUnreadMessage.messageId)
							}
							else if let lastMessage {
								scrollView.scrollTo(lastMessage.messageId)
							}
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
			}

			if let destination {
				Divider()

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
				.padding(.bottom, 8)
			}
			else {
				EmptyView()
			}
		}
		.navigationTitle(screenTitle)
		.navigationBarTitleDisplayMode(.large)
		.navigationBarItems(
			trailing: ZStack {
				if let channel {
					ConnectionInfo(
						mqttUplinkEnabled: channel.uplinkEnabled,
						mqttDownlinkEnabled: channel.downlinkEnabled
					)
				}
				else {
					ConnectionInfo()
				}
			}
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
				.listRowSeparator(.hidden)
				.listRowBackground(Color.clear)
				.scrollContentBackground(.hidden)
			}
			.listStyle(.plain)
			.background(colorScheme == .dark ? .black : .white)
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
		request.predicate = NSPredicate(format: "channel == %lld", channel.index)

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

	private func getUserColor(for node: NodeInfoEntity?) -> Color {
		if let node, node.isOnline {
			return Color(
				UIColor(hex: UInt32(node.num))
			)
		}
		else {
			return Color.gray.opacity(0.7)
		}
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
