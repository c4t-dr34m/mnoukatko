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
