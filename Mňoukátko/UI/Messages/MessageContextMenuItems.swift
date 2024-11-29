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
import SwiftUI

struct MessageContextMenuItems: View {
	@Binding
	var isShowingDeleteConfirmation: Bool

	let message: MessageEntity
	let tapBackDestination: MessageDestination
	let isCurrentUser: Bool
	let onReply: () -> Void

	@Environment(\.managedObjectContext)
	private var context

	var body: some View {
		Button {
			UIPasteboard.general.string = message.messagePayload
		} label: {
			Text("Copy message text")
			Image(systemName: "doc.on.doc")
		}

		Button(action: onReply) {
			Text("Reply")
			Image(systemName: "arrowshape.turn.up.left")
		}

		Divider()

		Button(role: .destructive) {
			isShowingDeleteConfirmation = true
		} label: {
			Text("delete")
			Image(systemName: "trash")
		}
	}
}

private extension MessageDestination {
	var managedObject: NSManagedObject {
		switch self {
		case let .user(user): return user
		case let .channel(channel): return channel
		}
	}
}
