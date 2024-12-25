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
import OSLog
import SwiftUI

struct FavoriteNodeButton: View {
	var node: NodeInfoEntity
	var nodeConfig: NodeConfig
	var context: NSManagedObjectContext

	@EnvironmentObject
	private var connectedDevice: CurrentDevice

	var body: some View {
		Button {
			guard let connectedNodeNum = connectedDevice.device?.num else {
				return
			}

			let success = if node.favorite {
				nodeConfig.removeFavoriteNode(
					node: node,
					connectedNodeNum: Int64(connectedNodeNum)
				)
			}
			else {
				nodeConfig.saveFavoriteNode(
					node: node,
					connectedNodeNum: Int64(connectedNodeNum)
				)
			}

			if success {
				node.favorite.toggle()

				do {
					try context.save()
				}
				catch {
					context.rollback()
					Logger.data.error("Save Node Favorite Error")
				}

				Logger.data.debug("Favorited a node")
			}
		} label: {
			Label {
				Text(node.favorite ? "Remove from favorites" : "Add to favorites")
			} icon: {
				Image(systemName: node.favorite ? "star.slash" : "star")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}
		}
	}
}
