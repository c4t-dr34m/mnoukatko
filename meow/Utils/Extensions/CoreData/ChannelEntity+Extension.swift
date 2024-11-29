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
import CoreData
import Foundation
import MeshtasticProtobufs

extension ChannelEntity {
	var allPrivateMessages: [MessageEntity]? {
		let context = Persistence.shared.container.viewContext
		let fetchRequest = MessageEntity.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(
				key: "messageTimestamp",
				ascending: true
			)
		]
		fetchRequest.predicate = NSPredicate(
			format: "channel == %ld AND toUser == nil",
			index
		)

		return try? context.fetch(fetchRequest)
	}

	var unreadMessages: Int {
		guard let allPrivateMessages else {
			return 0
		}

		return allPrivateMessages.filter { message in
			message.read == false
		}.count
	}

	var protoBuf: Channel {
		var channel = Channel()
		channel.index = index
		channel.settings.name = name ?? ""
		channel.settings.psk = psk ?? Data()
		channel.role = Channel.Role(rawValue: Int(role)) ?? Channel.Role.secondary
		channel.settings.moduleSettings.positionPrecision = UInt32(positionPrecision)

		return channel
	}
}
