import SwiftUI

struct SaveConfigButton: View {
	let node: NodeInfoEntity?
	let onConfirmation: () -> Void

	@Binding
	var hasChanges: Bool

	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@State
	private var isPresentingSaveConfirm = false

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
		.padding()
		.confirmationDialog(
			"Are you sure?",
			isPresented: $isPresentingSaveConfirm,
			titleVisibility: .visible
		) {
			let nodeName = node?.user?.longName ?? "Unknown"
			let buttonText = String.localizedStringWithFormat("Save")

			Button(buttonText) {
				onConfirmation()
			}
		} message: {
			Text("After config values save the node will reboot")
		}
	}
}
