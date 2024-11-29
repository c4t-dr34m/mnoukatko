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
