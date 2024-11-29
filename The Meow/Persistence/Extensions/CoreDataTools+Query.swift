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

extension CoreDataTools {
	public func getNodeInfo(id: Int64, context: NSManagedObjectContext) -> NodeInfoEntity? {
		let request = NodeInfoEntity.fetchRequest()
		request.predicate = NSPredicate(format: "num == %lld", Int64(id))

		if let nodes = try? context.fetch(request), nodes.count == 1 {
			return nodes[0]
		}

		return nil
	}

	public func getStoreAndForwardMessageIds(seconds: Int, context: NSManagedObjectContext) -> [UInt32] {
		let time = seconds * -1
		let timeRange = Calendar.current.date(byAdding: .minute, value: time, to: Date())
		let milleseconds = Int32(timeRange?.timeIntervalSince1970 ?? 0)

		let request = MessageEntity.fetchRequest()
		request.predicate = NSPredicate(format: "messageTimestamp >= %d", milleseconds)

		if let messages = try? context.fetch(request), messages.count == 1 {
			return messages.map { message in
				UInt32(message.messageId)
			}
		}

		return []
	}

	public func getTraceRoute(id: Int64, context: NSManagedObjectContext) -> TraceRouteEntity? {
		let request = TraceRouteEntity.fetchRequest()
		request.predicate = NSPredicate(format: "id == %lld", Int64(id))

		if let traceRoutes = try? context.fetch(request), traceRoutes.count == 1 {
			return traceRoutes[0]
		}

		return nil
	}

	public func getUser(id: Int64, context: NSManagedObjectContext) -> UserEntity {
		let request = UserEntity.fetchRequest()
		request.predicate = NSPredicate(format: "num == %lld", Int64(id))

		if let users = try?  context.fetch(request), users.count == 1 {
			return users[0]
		}

		return UserEntity(context: context)
	}
}
