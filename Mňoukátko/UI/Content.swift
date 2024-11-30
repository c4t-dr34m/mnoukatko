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
import OSLog
import SwiftUI

struct Content: View {
	private let debounce = Debounce<() async -> Void>(duration: .milliseconds(1000)) { action in
		await action()
	}

	@EnvironmentObject
	private var bleManager: BLEManager
	@Environment(\.scenePhase)
	private var scenePhase
	@StateObject
	private var appState = AppState.shared
	@State
	private var connectPresented = true
	@State
	private var connectWasDismissed = false

	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(key: "favorite", ascending: false),
			NSSortDescriptor(key: "lastHeard", ascending: false),
			NSSortDescriptor(key: "user.longName", ascending: true)
		],
		animation: .default
	)
	private var nodes: FetchedResults<NodeInfoEntity>
	private var nodeConnected: NodeInfoEntity? {
		nodes.first(where: { node in
			node.num == UserDefaults.preferredPeripheralNum
		})
	}
	private var nodeOnlineCount: Int {
		if bleManager.isNodeConnected {
			nodes.filter { node in
				node.isOnline
			}.count
		}
		else {
			0
		}
	}
	private var unreadMessagesCount: Int {
		guard let nodeConnected else {
			return 0
		}

		let channelUnreadMessages = nodeConnected.user?.unreadMessages ?? 0
		let usersUnreadMessages = nodeConnected.myInfo?.unreadMessages ?? 0

		return channelUnreadMessages + usersUnreadMessages
	}

	@ViewBuilder
	var body: some View {
		TabView(selection: $appState.tabSelection) {
			Messages()
				.tabItem {
					Label("Messages", systemImage: "message")
				}
				.tag(ContentTab.messages)
				.badge(unreadMessagesCount)

			NodeList()
				.tabItem {
					Label("Nodes", systemImage: "flipphone")
				}
				.tag(ContentTab.nodes)
				.badge(nodeOnlineCount)

			MeshMap(node: nodeConnected)
				.tabItem {
					Label("Mesh", systemImage: "map")
				}
				.tag(ContentTab.map)

			Options()
				.tabItem {
					Label("Options", systemImage: "gearshape")
				}
				.tag(ContentTab.options)
		}
		.onChange(of: bleManager.info, initial: true) {
			processBleManagerState()
		}
		.onChange(of: bleManager.isSubscribed, initial: true) {
			processBleManagerState()
		}
		.onChange(of: bleManager.isConnected, initial: true) {
			processBleManagerState()
		}
		.onChange(of: bleManager.isConnecting, initial: true) {
			processBleManagerState()
		}
		.onChange(of: bleManager.lastConnectionError, initial: true) {
			guard scenePhase != .background else {
				return
			}

			if !bleManager.lastConnectionError.isEmpty, !connectWasDismissed {
				connectPresented = true
			}
		}
		.onOpenURL { url in
			AppState.shared.navigation = Navigation(from: url)
		}
		.sheet(isPresented: $connectPresented) {
			connectPresented = false
			connectWasDismissed = true

			bleManager.connectMQTT()
		} content: {
			Connect(isInSheet: true)
				.presentationDetents([.large])
				.presentationDragIndicator(.visible)
		}
	}

	private func processBleManagerState() {
		if bleManager.isSubscribed, bleManager.isConnected {
			connectWasDismissed = false

			debounce.emit {
				if !checkLastChange() {
					debounce.emit { // check again later
						checkLastChange()
					}
				}
			}
		}
		else if !connectWasDismissed, scenePhase != .background {
			connectPresented = true
		}
	}

	@discardableResult
	private func checkLastChange() -> Bool {
		if bleManager.infoLastChanged?.isStale(threshold: 1) ?? true {
			connectPresented = false

			return true
		}

		return false
	}
}
