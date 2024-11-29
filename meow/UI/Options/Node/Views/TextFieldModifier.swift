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
