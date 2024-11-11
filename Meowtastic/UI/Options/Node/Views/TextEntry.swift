import SwiftUI

struct TextEntry: View {
	private let monospaced: Bool
	private let placeholder: String?
	private let validator: ((String) -> Bool)?

	@Binding
	private var text: String
	@State
	private var borderColor: Color = .gray.opacity(0.4)

	@ViewBuilder
	var body: some View {
		if monospaced {
			TextField(placeholder ?? "", text: $text)
				.font(.body)
				.monospaced()
				.autocorrectionDisabled()
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(borderColor, lineWidth: 2)
				)
				.clipShape(
					RoundedRectangle(cornerRadius: 16)
				)
				.frame(minHeight: 32)
				.onChange(of: text, initial: true) {
					validate()
				}
		}
		else {
			TextField(placeholder ?? "", text: $text)
				.font(.body)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(borderColor, lineWidth: 2)
				)
				.clipShape(
					RoundedRectangle(cornerRadius: 16)
				)
				.frame(minHeight: 32)
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
		if validator?(text) ?? true {
			borderColor = .gray.opacity(0.4)
		}
		else {
			borderColor = .red
		}
	}
}
