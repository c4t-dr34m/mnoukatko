import CoreData
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct Messages: View {
	private let coreDataTools = CoreDataTools()
	private let restrictedChannels = ["gpio", "mqtt", "serial"]
	private let debounce = Debounce<() async -> Void>(duration: .milliseconds(250)) { action in
		await action()
	}
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailIconSize: CGFloat = 16

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@StateObject
	private var appState = AppState.shared
	@State
	private var selectedChannel: ChannelEntity? // Nothing selected by default.
	@State
	private var selectedUser: UserEntity? // Nothing selected by default.
	@State
	private var selectedConversationPresented = false
	@State
	private var isPresentingTraceRouteSentAlert = false
	@State
	private var isPresentingDeleteChannelMessagesConfirm: Bool = false
	@State
	private var isPresentingDeleteUserMessagesConfirm = false
	@FetchRequest(
		sortDescriptors: [],
		predicate: NSPredicate(
			format: "num == %lld", Int64(UserDefaults.preferredPeripheralNum)
		)
	)
	private var nodes: FetchedResults<NodeInfoEntity>
	@FetchRequest(sortDescriptors: [])
	private var users: FetchedResults<UserEntity>
	private var node: NodeInfoEntity? {
		nodes.first
	}

	private var usersFiltered: [UserEntity] {
		var filtered = users.filter { user in
			guard user.userNode != nil else {
				return false
			}

			if let num = connectedDevice.device?.num, user.num == num {
				return false
			}

			return true
		}

		filtered.sort { user1, user2 in
			let u1lm = user1.lastMessage
			let u2lm = user2.lastMessage
			let u1ln = user1.longName
			let u2ln = user2.longName

			// swiftlint:disable:next force_unwrapping
			if let u1lm, u2lm == nil || u1lm > u2lm! {
				return true
			}
			// swiftlint:disable:next force_unwrapping
			if let u2lm, u1lm == nil || u1lm! >= u2lm {
				return false
			}

			// swiftlint:disable:next force_unwrapping
			if let u1ln, u2ln == nil || u1ln.compare(u2ln!, options: .caseInsensitive) == .orderedAscending {
				return true
			}
			else {
				return false
			}
		}

		return filtered
	}

	private var channels: [ChannelEntity] {
		if let channels = node?.myInfo?.channels?.array as? [ChannelEntity] {
			return channels.filter { channel in
				guard channel.role != Channel.Role.disabled.rawValue else {
					return false
				}

				if let name = channel.name {
					return !restrictedChannels.contains(name.lowercased())
				}

				return true
			}
		}

		return []
	}

	var body: some View {
		NavigationStack {
			List {
				channelList
				userList
			}
			.listStyle(.automatic)
			.disableAutocorrection(true)
			.scrollDismissesKeyboard(.immediately)
			.navigationTitle("Messages")
			.navigationBarItems(
				trailing: ConnectionInfo()
			)
			.navigationDestination(
				isPresented: $selectedConversationPresented,
				destination: {
					if let selectedUser {
						NavigationLazyView(
							MessageList(user: selectedUser, myInfo: node?.myInfo)
						)
					}
					else if let selectedChannel {
						NavigationLazyView(
							MessageList(channel: selectedChannel, myInfo: node?.myInfo)
						)
					}
				}
			)
		}
		.onAppear {
			Analytics.logEvent(AnalyticEvents.messages.id, parameters: nil)
		}
		.onChange(of: appState.navigation, initial: true) {
			guard case let .messages(channel, user, _) = appState.navigation else {
				return
			}

			if let user {
				selectedUser = users.first(where: { usr in
					usr.num == user
				})
				selectedConversationPresented = true
			}
			else if let channel {
				selectedChannel = channels.first(where: { ch in
					ch.index == channel
				})
				selectedConversationPresented = true
			}
		}
		.onChange(of: selectedConversationPresented) {
			if !selectedConversationPresented {
				AppState.shared.navigation = nil
			}
		}
	}

	@ViewBuilder
	private var channelList: some View {
		if !channels.isEmpty {
			Section(
				header: listHeader(
					title: "Channels",
					nodesCount: channels.count
				)
			) {
				ForEach(channels, id: \.index) { channel in
					makeChannelLink(for: channel)
						.contextMenu {
							Button {
								guard let user = node?.user else {
									return
								}

								channel.mute.toggle()

								let adminMessageId = nodeConfig.saveChannel(
									channel: channel.protoBuf,
									fromUser: user,
									toUser: user
								)

								if adminMessageId > 0 {
									context.refresh(channel, mergeChanges: true)
								}

								debounce.emit {
									await self.saveData()
								}
							} label: {
								Label(
									channel.mute ? "Show Alerts" : "Hide Alerts",
									systemImage: channel.mute ? "bell" : "bell.slash"
								)
							}
						}
						.confirmationDialog(
							"Messages in the channel will be deleted",
							isPresented: $isPresentingDeleteChannelMessagesConfirm,
							titleVisibility: .visible
						) {
							Button(role: .destructive) {
								guard let selectedChannel else {
									return
								}

								coreDataTools.deleteChannelMessages(channel: selectedChannel, context: context)
								if let myInfo = node?.myInfo {
									context.refresh(myInfo, mergeChanges: true)
								}

								self.selectedChannel = nil
							} label: {
								Text("Delete")
							}
						}
				}
			}
			.headerProminence(.increased)
		}
	}

	@ViewBuilder
	private var userList: some View {
		Section(
			header: listHeader(
				title: "Users",
				nodesCount: usersFiltered.count
			)
		) {
			ForEach(usersFiltered, id: \.num) { user in
				if user.num != connectedDevice.device?.num ?? 0 {
					makeUserLink(for: user)
				}
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	private func listHeader(title: String, nodesCount: Int) -> some View {
		HStack(alignment: .center) {
			Text(title)
				.fontDesign(.rounded)

			Spacer()

			Text(String(nodesCount))
				.fontDesign(.rounded)
		}
	}

	@ViewBuilder
	private func makeChannelLink(for channel: ChannelEntity) -> some View {
		NavigationLink {
			NavigationLazyView(
				MessageList(channel: channel, myInfo: node?.myInfo)
			)
		} label: {
			HStack(spacing: 8) {
				avatar(for: channel)

				HStack(alignment: .top) {
					VStack(alignment: .leading, spacing: 8) {
						if let name = channel.name, !name.isEmpty {
							Text(name.camelCaseToWords())
								.lineLimit(1)
								.font(.headline)
								.minimumScaleFactor(0.5)
						}
						else {
							if channel.role == 1 {
								Text("Primary Channel")
									.font(.headline)
									.lineLimit(1)
									.font(.headline)
									.minimumScaleFactor(0.5)
							}
							else {
								Text("Channel #\(channel.index)")
									.font(.headline)
									.lineLimit(1)
									.font(.headline)
									.minimumScaleFactor(0.5)
							}
						}

						if let lastMessage = channel.allPrivateMessages?.last?.timestamp {
							HStack {
								Image(systemName: "bubble.fill")
									.font(detailInfoFont)
									.foregroundColor(.gray)

								Text(lastMessage.relative())
									.font(detailInfoFont)
									.foregroundColor(.gray)
							}
						}
					}

					Spacer()
				}
			}
		}
	}

	@ViewBuilder
	private func makeUserLink(for user: UserEntity) -> some View {
		NavigationLink {
			NavigationLazyView(
				MessageList(user: user, myInfo: node?.myInfo)
			)
		} label: {
			HStack(spacing: 8) {
				avatar(for: user)

				HStack(alignment: .top) {
					VStack(alignment: .leading, spacing: 8) {
						Text(user.longName ?? "Unknown user")
							.lineLimit(1)
							.font(.headline)
							.minimumScaleFactor(0.5)

						if let lastMessage = user.lastMessage {
							HStack {
								Image(systemName: "bubble.fill")
									.font(detailInfoFont)
									.foregroundColor(.gray)

								Text(lastMessage.relative())
									.font(detailInfoFont)
									.foregroundColor(.gray)
							}
						}
					}

					Spacer()
				}
			}
		}
	}

	@ViewBuilder
	private func avatar(for user: UserEntity) -> some View {
		ZStack(alignment: .top) {
			if let node = user.userNode {
				AvatarNode(
					node,
					showLastHeard: node.isOnline,
					size: 64
				)
				.padding([.top, .bottom, .trailing], 12)
			}
			else {
				AvatarAbstract(
					size: 64
				)
				.padding([.top, .bottom, .trailing], 12)
			}

			if user.unreadMessages > 0 {
				HStack(spacing: 0) {
					Spacer()

					if user.unreadMessages <= 50 {
						Image(systemName: "\(user.unreadMessages).circle")
							.font(.system(size: 24))
							.foregroundColor(.red)
							.background(
								Circle()
									.foregroundColor(.listBackground(for: colorScheme))
							)
					}
					else {
						Image(systemName: "book.closed.circle.fill")
							.font(.system(size: 24))
							.foregroundColor(.red)
							.background(
								Circle()
									.foregroundColor(.listBackground(for: colorScheme))
							)
					}
				}
			}
			else if user.userNode?.favorite ?? false {
				HStack(spacing: 0) {
					Spacer()

					Image(systemName: "star.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(colorScheme == .dark ? .white : .gray)
						.background(
							Circle()
								.foregroundColor(.listBackground(for: colorScheme))
						)
				}
			}
		}
		.frame(width: 80, height: 80)
	}

	@ViewBuilder
	private func avatar(for channel: ChannelEntity) -> some View {
		ZStack(alignment: .top) {
			AvatarAbstract(
				String(channel.index),
				size: 64
			)
			.padding([.top, .bottom, .trailing], 12)

			if channel.unreadMessages > 0 {
				HStack(spacing: 0) {
					Spacer()

					Image(systemName: "circle.fill")
						.font(.system(size: 24))
						.foregroundColor(.red)
				}
			}
		}
		.frame(width: 80, height: 80)
	}

	@ViewBuilder
	private func getContextMenu(for user: UserEntity, hasMessages: Bool) -> some View {
		Button {
			if let node, let userNode = user.userNode, !userNode.favorite {
				let success: Bool
				if userNode.favorite {
					success = nodeConfig.removeFavoriteNode(
						node: userNode,
						connectedNodeNum: Int64(node.num)
					)
				}
				else {
					success = nodeConfig.saveFavoriteNode(
						node: userNode,
						connectedNodeNum: Int64(node.num)
					)
				}

				if success {
					userNode.favorite.toggle()
				}
			}

			context.refresh(user, mergeChanges: true)

			debounce.emit {
				await self.saveData()
			}
		} label: {
			Label(
				user.userNode?.favorite ?? false ? "Un-Favorite" : "Favorite",
				systemImage: user.userNode?.favorite ?? false ? "star.slash.fill" : "star.fill"
			)
		}

		Button {
			user.mute.toggle()

			debounce.emit {
				await self.saveData()
			}
		} label: {
			Label(
				user.mute ? "Show Alerts" : "Hide Alerts",
				systemImage: user.mute ? "bell" : "bell.slash"
			)
		}

		if hasMessages {
			Button(role: .destructive) {
				isPresentingDeleteUserMessagesConfirm = true
				selectedUser = user
			} label: {
				Label("Delete Messages", systemImage: "trash")
			}
		}
	}

	private func getUserColor(for user: UserEntity) -> Color {
		if
			let num = user.userNode?.num,
			user.userNode?.isOnline ?? false
		{
			return Color(
				UIColor(hex: UInt32(num))
			)
		}

		return Color.gray.opacity(0.7)
	}

	private func getLastMessage(for user: UserEntity) -> MessageEntity? {
		user.messageList?.last
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
