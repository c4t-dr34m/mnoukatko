import SwiftUI

protocol OptionsScreen: View {
	var node: NodeInfoEntity { get set }
	var coreDataTools: CoreDataTools { get set }

	func save()
	func setInitialValues()
	func validateSession(for node: NodeInfoEntity) -> Bool
}

extension OptionsScreen {
	func validateSession(for node: NodeInfoEntity) -> Bool {
		let administration = UserDefaults.enableAdministration
		let sessionExp = node.sessionExpiration

		if administration {
			if let sessionExp, sessionExp >= Date.now {
				return true
			}
			else {
				return false
			}
		}
		else {
			return true
		}
	}
}
