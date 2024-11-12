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
