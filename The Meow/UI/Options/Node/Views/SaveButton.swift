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
import SwiftUI

struct SaveButton: View {
	private let willReboot: Bool
	private let onSave: () -> Void

	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@Binding
	private var changes: Bool
	@State
	private var isPresentingSaveConfirm = false

	private var isDisabled: Bool {
		connectedDevice.device == nil || !changes
	}

	@ViewBuilder
	var body: some View {
		Button {
			if willReboot {
				isPresentingSaveConfirm = true
			}
			else {
				onSave()
			}
		} label: {
			HStack(alignment: .center, spacing: 8) {
				Image(systemName: "square.and.arrow.down")
					.resizable()
					.scaledToFit()
					.frame(width: 16, height: 16)
					.foregroundColor(changes ? .green : .gray)

				Text("Save")
					.font(.system(size: 14))
					.foregroundColor(changes ? .green : .gray)
			}
			.padding(.vertical, 8)
			.padding(.horizontal, 16)
			.background(changes ? .green.opacity(0.3) : .gray.opacity(0.3))
			.clipShape(RoundedRectangle(cornerRadius: 12))
		}
		.disabled(isDisabled)
		.confirmationDialog(
			"Are you sure?",
			isPresented: $isPresentingSaveConfirm,
			titleVisibility: .visible
		) {
			Button("Save configuration") {
				onSave()
			}
		} message: {
			Text("Node will reboot after saving changes.")
		}
	}

	init(
		changes: Binding<Bool>,
		willReboot: Bool = true,
		onSave: @escaping () -> Void
	) {
		self._changes = changes
		self.willReboot = willReboot
		self.onSave = onSave
	}
}
