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
