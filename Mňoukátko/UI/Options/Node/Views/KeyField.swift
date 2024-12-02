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
import SwiftUI

struct KeyField: View {
	private let monospaced: Bool
	private let placeholder: String?
	private let validator: ((String) -> Bool)?

	@Binding
	private var text: String
	@State
	private var invalid: Bool = false

	@ViewBuilder
	var body: some View {
		if monospaced {
			TextField(placeholder ?? "", text: $text)
				.optionsStyle(invalid: $invalid)
				.monospaced()
				.autocorrectionDisabled()
				.onChange(of: text, initial: true) {
					validate()
				}
		}
		else {
			TextField(placeholder ?? "", text: $text)
				.optionsStyle(invalid: $invalid)
				.onChange(of: text, initial: true) {
					validate()
				}
		}
	}

	init(
		_ text: Binding<String>,
		monospaced: Bool = false,
		placeholder: String? = nil,
		_ validator: ((String) -> Bool)? = nil
	) {
		self._text = text
		self.monospaced = monospaced
		self.placeholder = placeholder
		self.validator = validator
	}

	private func validate() {
		invalid = !(validator?(text) ?? true)
	}
}
