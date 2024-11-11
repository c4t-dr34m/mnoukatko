import SwiftUI

struct SaveConfigButton: View {
	private let node: NodeInfoEntity
	private let onSave: () -> Void

	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@State
	private var isPresentingSaveConfirm = false
	@Binding
	private var hasChanges: Bool

	@ViewBuilder
	var body: some View {
		Button {
			isPresentingSaveConfirm = true
		} label: {
			Label("Save", systemImage: "square.and.arrow.down")
		}
		.disabled(connectedDevice.device == nil || !hasChanges)
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.controlSize(.large)
		.padding(.all, 8)
		.confirmationDialog(
			"Are you sure?",
			isPresented: $isPresentingSaveConfirm,
			titleVisibility: .visible
		) {
			let buttonText = String.localizedStringWithFormat("Save")

			Button(buttonText) {
				onSave()
			}
		} message: {
			Text("After config values save the node will reboot")
		}
	}

	init(
		node: NodeInfoEntity,
		hasChanges: Binding<Bool>,
		onSave: @escaping () -> Void
	) {
		self.node = node
		self._hasChanges = hasChanges
		self.onSave = onSave
	}
}
