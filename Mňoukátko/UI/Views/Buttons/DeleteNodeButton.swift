/*
Mňoukátko - the Meshtastic® client

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
import SwiftUI

struct DeleteNodeButton: View {
	var node: NodeInfoEntity
	var nodeConfig: NodeConfig
	var connectedNode: NodeInfoEntity
	var context: NSManagedObjectContext

	private let coreDataTools = CoreDataTools()

	@State
	private var isPresentingAlert = false

	@ViewBuilder
	var body: some View {
		Button(role: .destructive) {
			isPresentingAlert = true
		} label: {
			Label {
				Text("Delete Node")
			} icon: {
				Image(systemName: "trash")
					.symbolRenderingMode(.monochrome)
			}
		}
		.confirmationDialog(
			"Are you sure?",
			isPresented: $isPresentingAlert,
			titleVisibility: .visible
		) {
			Button("Delete Node", role: .destructive) {
				guard let nodeToDelete = coreDataTools.getNodeInfo(id: node.num, context: context) else {
					return
				}

				nodeConfig.removeNode(
					node: nodeToDelete,
					connectedNodeNum: connectedNode.num
				)
			}
		}
	}
}
