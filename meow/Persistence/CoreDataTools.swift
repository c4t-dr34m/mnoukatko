/*
Meow - the Meshtastic® client

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

final class CoreDataTools {
	let debounce = Debounce<() async -> Void>(duration: .milliseconds(606)) { action in
		await action()
	}

	@discardableResult
	func saveData(with context: NSManagedObjectContext) async -> Bool {
		await context.perform {
			guard context.hasChanges else {
				return false
			}

			do {
				try context.save()

				return true
			}
			catch {
				context.rollback()

				return false
			}
		}
	}
}
