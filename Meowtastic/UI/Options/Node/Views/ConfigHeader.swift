import CoreData
import SwiftUI

struct ConfigHeader<T>: View {
	let title: String
	let config: KeyPath<NodeInfoEntity, T?>
	let node: NodeInfoEntity?

	@EnvironmentObject
	private var connectedDevice: CurrentDevice

	var body: some View {
		if let node {
			if node.metadata == nil, node.num != connectedDevice.device?.num ?? 0 {
				Text("There has been no response to a request for device metadata over the admin channel for this node.")
					.font(.callout)
					.foregroundColor(.accentColor)
			}
			else if node.num != connectedDevice.device?.num ?? 0 {
				// Let users know what is going on if they are using remote admin and don't have the config yet
				if node[keyPath: config] == nil {
					Text("\(title) config data was requested over the admin channel but no response has been returned from the remote node. You can check the status of admin message requests in the admin message log.")
						.font(.callout)
						.foregroundColor(.accentColor)
				}
				else {
					Text("Remote administration for: \(node.user?.longName ?? "Unknown node")")
						.font(.title3)
				}
			}
			else if node.num == connectedDevice.device?.num ?? -1 {
				Text("Configuration for: \(node.user?.longName ?? "Unknown node")")
			}
			else {
				Text("Please connect to a radio to configure settings.")
					.font(.callout)
					.foregroundColor(.accentColor)
			}
		}
		else {
			Text("Please connect to a radio to configure settings.")
				.font(.callout)
				.foregroundColor(.accentColor)
		}
	}
}
