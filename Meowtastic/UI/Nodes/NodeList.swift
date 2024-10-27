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
	private var selectedNodePresented: Bool = false

	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(key: "favorite", ascending: false),
			NSSortDescriptor(key: "lastHeard", ascending: false),
			NSSortDescriptor(key: "hopsAway", ascending: true),
			NSSortDescriptor(key: "user.longName", ascending: true)
		]
	)
	private var nodes: FetchedResults<NodeInfoEntity>
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

				nodeListOnline
				nodeListOffline
			}
			.listStyle(.automatic)
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
		let nodeList = nodes.filter { node in
			node.num != connectedNodeNum && node.isOnline == true
		}

		Section(
			header: listHeader(
				title: "Online",
				nodesCount: nodeList.count
			)
		) {
			ForEach(nodeList, id: \.num) { node in
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
		let nodeList = nodes.filter { node in
			node.num != connectedNodeNum && node.isOnline == false
		}

		Section(
			header: listHeader(
				title: "Offline",
				nodesCount: nodeList.count,
				collapsible: true,
				property: $showOffline
			)
		) {
			if showOffline {
				ForEach(nodeList, id: \.num) { node in
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
