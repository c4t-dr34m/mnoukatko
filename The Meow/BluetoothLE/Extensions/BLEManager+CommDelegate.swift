/*
The Meow - the Meshtastic® client

Copyright © 2022-2024 Garth Vander Houwen
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
