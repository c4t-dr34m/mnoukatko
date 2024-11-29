/*
Meow - the Meshtastic® client

Copyright (C) 2022-2024 Garth Vander Houwen
Copyright (C) 2024 Radovan Paška

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
import Foundation

extension MyInfoEntity {
	var messageList: [MessageEntity]? {
		let context = Persistence.shared.container.viewContext
		let fetchRequest = MessageEntity.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(
				key: "messageTimestamp",
				ascending: true
			)
		]
		fetchRequest.predicate = NSPredicate(
			format: "toUser == nil"
		)

		return try? context.fetch(fetchRequest)
	}

	var unreadMessages: Int {
		guard let messageList else {
			return 0
		}

		return messageList.filter { message in
			message.read == false
		}.count
	}

	var hasAdmin: Bool {
		guard let channels else {
			return false
		}

		return channels.contains { channel in
			(channel as AnyObject).name?.lowercased() == "admin"
		}
	}
}
