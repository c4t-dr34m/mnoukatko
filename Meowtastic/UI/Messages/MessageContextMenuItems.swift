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
