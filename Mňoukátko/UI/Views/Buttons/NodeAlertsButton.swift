/*
Mňoukátko - a Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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
import SwiftUI

struct NodeAlertsButton: View {
	var node: NodeInfoEntity
	var user: UserEntity
	var context: NSManagedObjectContext

	var body: some View {
		Button {
			user.mute.toggle()
			context.refresh(node, mergeChanges: true)

			do {
				try context.save()
			}
			catch {
				context.rollback()
				Logger.data.error("Save User Mute Error")
			}
		} label: {
			Label {
				Text(user.mute ? "Show alerts" : "Hide alerts")
			} icon: {
				Image(systemName: user.mute ? "bell.slash" : "bell")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}
		}
	}
}
