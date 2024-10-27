import CoreData
import OSLog

extension BLEManager: CommDelegate {
	func onTraceRouteReceived(for node: NodeInfoEntity?) {
		// no-op
	}

	func onNodeConfigReceived(_ type: ConfigType, num: Int64) {
		let nodeName = getNodeName(for: num)
		updateInfo(with: "\(type.rawValue.uppercaseFirstLetter()) config for \(nodeName)")
	}

	func onNodeModuleConfigReceived(_ type: ConfigType, num: Int64) {
		let nodeName = getNodeName(for: num)
		updateInfo(with: "\(type.rawValue.uppercaseFirstLetter()) config for \(nodeName)")
	}

	func onChannelInfoReceived(index: Int32, name: String?, num: Int64) {
		let channelLabel: String
		if let name, !name.isEmpty {
			channelLabel = name
		}
		else {
			channelLabel = "#\(index)"
		}

		updateInfo(with: "Channel info for \(channelLabel)")
	}

	func onMyInfoReceived(num: Int64) {
		let nodeName = getNodeName(for: num)
		updateInfo(with: "Node info for \(nodeName)")
	}

	func onInfoReceived(num: Int64) {
		let nodeName = getNodeName(for: num)
		updateInfo(with: "Node info for \(nodeName)")
	}

	func onMetadataReceived(num: Int64) {
		let nodeName = getNodeName(for: num)
		updateInfo(with: "Metadata for \(nodeName)")
	}

	private func updateInfo(with newInfo: String) {
		info = newInfo
		infoChangeCount += 1
		infoLastChanged = .now

		if let info {
			Logger.app.debug("\(info)")
		}
	}

	private func getNodeName(for num: Int64) -> String {
		if let nodeName = nodeNames[num] {
			return nodeName
		}

		let request = NodeInfoEntity.fetchRequest()
		request.predicate = NSPredicate(format: "num == %lld", num)

		let nodeName: String
		if
			let nodes = try? context.fetch(request),
			let node = nodes.first,
			let longName = node.user?.longName
		{
			nodeName = longName
		}
		else {
			nodeName = "#\(num)"
		}

		nodeNames[num] = nodeName

		return nodeName
	}
}

private extension String {
	func uppercaseFirstLetter() -> String {
		prefix(1).uppercased() + self.lowercased().dropFirst()
	}
}
