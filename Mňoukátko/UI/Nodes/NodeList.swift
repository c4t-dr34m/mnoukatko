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
import CoreData
import FirebaseAnalytics
import OSLog
import SwiftUI

struct NodeList: View {
	private let coreDataTools = CoreDataTools()
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailIconSize: CGFloat = 16

	@SceneStorage("selectedDetailView")
	private var selectedDetailView: String?
	@Environment(\.managedObjectContext)
	private var context
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@StateObject
	private var appState = AppState.shared
	@State
	private var showOffline = false
	@State
	private var selectedNode: NodeInfoEntity?
	@State
	private var selectedNodePresented = false

	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(key: "favorite", ascending: false),
			NSSortDescriptor(key: "lastHeard", ascending: false),
			NSSortDescriptor(key: "hopsAway", ascending: true),
			NSSortDescriptor(key: "user.longName", ascending: true)
		]
	)
	private var nodes: FetchedResults<NodeInfoEntity>
	private var nodesOnline: [NodeInfoEntity] {
		if connectedDevice.device == nil {
			return []
		}

		return nodes.filter { node in
			node.num != connectedNodeNum && node.isOnline == true
		}
	}
	private var nodesOffline: [NodeInfoEntity] {
		if connectedDevice.device == nil {
			return nodes.map { node in
				node
			}
		}

		return nodes.filter { node in
			node.num != connectedNodeNum && node.isOnline == false
		}

	}
	private var connectedNode: NodeInfoEntity? {
		coreDataTools.getNodeInfo(
			id: connectedNodeNum,
			context: context
		)
	}
	private var connectedNodeNum: Int64 {
		Int64(connectedDevice.device?.num ?? 0)
	}

	var body: some View {
		NavigationStack {
			List(selection: $selectedNode) {
				if connectedNode != nil {
					Section(
						header: Text("Summary").fontDesign(.rounded)
					) {
						NodeListSummary()
					}
					.headerProminence(.increased)

					Section(
						header: Text("Connected Device").fontDesign(.rounded)
					) {
						NodeListConnectedItem()
					}
					.headerProminence(.increased)
				}
				else {
					NavigationLink {
						NavigationLazyView(
							Connect(node: connectedNode)
						)
					} label: {
						Text("Connection")
					}
				}

				nodeListOnline
				nodeListOffline
			}
			.listStyle(.insetGrouped)
			.disableAutocorrection(true)
			.scrollDismissesKeyboard(.interactively)
			.navigationTitle("Nodes")
			.navigationBarItems(
				trailing: ConnectionInfo()
			)
			.navigationDestination(
				isPresented: $selectedNodePresented,
				destination: {
					if let selectedNode {
						NavigationLazyView(
							NodeDetail(node: selectedNode)
						)
					}
				}
			)
		}
		.onAppear {
			Analytics.logEvent(
				AnalyticEvents.nodeList.id,
				parameters: [
					"nodes_in_list": nodes.count
				]
			)
		}
		.onChange(of: appState.navigation, initial: true) {
			guard case let .nodes(num) = appState.navigation, let num else {
				return
			}

			selectedNode = nodes.first(where: { node in
				node.num == num
			})
			selectedNodePresented = true
		}
		.onChange(of: selectedNodePresented) {
			if !selectedNodePresented {
				AppState.shared.navigation = nil
			}
		}
	}

	@ViewBuilder
	private var nodeListOnline: some View {
		Section(
			header: listHeader(
				title: "Online",
				nodesCount: nodesOnline.count
			)
		) {
			ForEach(nodesOnline, id: \.num) { node in
				NodeListItem(
					node: node,
					connected: connectedDevice.device?.num ?? -1 == node.num
				)
				.contextMenu {
					contextMenuActions(
						node: node,
						connectedNode: connectedNode
					)
				}
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	private var nodeListOffline: some View {
		Section(
			header: listHeader(
				title: "Offline",
				nodesCount: nodesOffline.count,
				collapsible: !nodesOnline.isEmpty,
				property: $showOffline
			)
		) {
			if showOffline || nodesOnline.isEmpty {
				ForEach(nodesOffline, id: \.num) { node in
					NodeListItem(
						node: node,
						connected: connectedDevice.device?.num ?? -1 == node.num
					)
					.contextMenu {
						contextMenuActions(
							node: node,
							connectedNode: connectedNode
						)
					}
				}
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	private func listHeader(
		title: String,
		nodesCount: Int? = nil,
		collapsible: Bool = false,
		property: Binding<Bool>? = nil
	) -> some View {
		HStack(alignment: .center) {
			Text(title)
				.fontDesign(.rounded)

			Spacer()

			if collapsible, property != nil {
				Button(
					action: {
						withAnimation {
							property?.wrappedValue.toggle()
						}
					},
					label: {
						// swiftlint:disable:next force_unwrapping
						let nodesCountText = nodesCount != nil ? " \(nodesCount!) nodes" : ""

						if property?.wrappedValue == true {
							Text("Hide" + nodesCountText)
								.fontDesign(.rounded)
						}
						else {
							Text("Show" + nodesCountText)
								.fontDesign(.rounded)
						}
					}
				)
			}
			else {
				if let nodesCount {
					Text(String(nodesCount))
						.fontDesign(.rounded)
				}
				else {
					EmptyView()
				}
			}
		}
	}

	@ViewBuilder
	private func contextMenuActions(
		node: NodeInfoEntity,
		connectedNode: NodeInfoEntity?
	) -> some View {
		FavoriteNodeButton(
			node: node,
			nodeConfig: nodeConfig,
			context: context
		)

		if let user = node.user {
			NodeAlertsButton(
				node: node,
				user: user,
				context: context
			)
		}

		if let connectedNode {
			DeleteNodeButton(
				node: node,
				nodeConfig: nodeConfig,
				connectedNode: connectedNode,
				context: context
			)
		}
	}
}

extension FetchedResults<NodeInfoEntity>: @retroactive Equatable {
	public static func == (
		lhs: FetchedResults<NodeInfoEntity>,
		rhs: FetchedResults<NodeInfoEntity>
	) -> Bool {
		lhs.elementsEqual(rhs)
	}
}
