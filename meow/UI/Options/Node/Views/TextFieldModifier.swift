/*
Meow - the Meshtastic® client

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

struct TextFieldModifier: ViewModifier {
	@Binding
	var invalid: Bool

	func body(content: Self.Content) -> some View {
		content
			.textFieldStyle(.plain)
			.foregroundColor(.gray)
			.lineLimit(0...3)
			.multilineTextAlignment(.trailing)
			.frame(maxWidth: 200)
			.overlay(
				VStack {
					Spacer()
					Rectangle()
						.frame(height: 1, alignment: .bottom)
						.foregroundColor(invalid ? .red : .gray.opacity(0.75))
					Spacer()
						.frame(height: 3)
				}
			)
			.scrollDismissesKeyboard(.interactively)
	}
}

extension TextField {
	func optionsStyle(invalid: Binding<Bool> = .constant(false)) -> some View {
		modifier(
			TextFieldModifier(invalid: invalid)
		)
	}
}
