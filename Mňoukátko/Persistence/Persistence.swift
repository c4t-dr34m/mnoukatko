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

final class Persistence {
	static let shared = Persistence()

	static var preview: Persistence = {
		let result = Persistence(inMemory: false)
		let context = result.container.viewContext

		for _ in 0..<10 {
			let newItem = NodeInfoEntity(context: context)
			newItem.lastHeard = Date()
		}

		try? context.save()

		return result
	}()

	let container: NSPersistentContainer

	init(inMemory: Bool = false) {
		container = NSPersistentContainer(name: "Mňoukátko")

		if inMemory {
			container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
		}

		container.loadPersistentStores { [weak self] _, error in
			guard let self else {
				return
			}

			// Merge policy that favors in memory data over data in the db
			self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
			self.container.viewContext.automaticallyMergesChangesFromParent = true

			if let error = error as NSError? {
				Logger.data.error("CoreData Error: \(error.localizedDescription). Now attempting to truncate CoreData database.  All app data will be lost.")

				self.clearDatabase()
			}
		}
	}

	func clearDatabase() {
		guard let url = container.persistentStoreDescriptions.first?.url else {
			return
		}

		let coordinator = container.persistentStoreCoordinator

		do {
			try coordinator.destroyPersistentStore(
				at: url,
				ofType: NSSQLiteStoreType,
				options: nil
			)

			do {
				try coordinator.addPersistentStore(
					ofType: NSSQLiteStoreType,
					configurationName: nil,
					at: url,
					options: nil
				)
			}
			catch let error {
				Logger.data.error("Failed to re-create CoreData database: \(error.localizedDescription)")
			}
		}
		catch let error {
			Logger.data.error("Failed to destroy CoreData database, delete the app and re-install to clear data. Attempted to clear persistent store: \(error.localizedDescription)")
		}
	}
}
