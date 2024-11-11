import SwiftUI

struct SaveConfigButton: View {
	private let node: NodeInfoEntity
	private let onSave: () -> Void

	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@Binding
	private var hasChanges: Bool
	@State
	private var isPresentingSaveConfirm = false

	@ViewBuilder
	var body: some View {
		Button {
			isPresentingSaveConfirm = true
		} label: {
			Image(systemName: "square.and.arrow.down")
				.font(.system(size: 32))
				.foregroundStyle(Color.accentColor)
		}
		.disabled(connectedDevice.device == nil || !hasChanges)
		.padding(.all, 8)
		.buttonStyle(.bordered)
		.buttonBorderShape(.circle)
		.controlSize(.large)
		.frame(alignment: .bottomTrailing)
		.confirmationDialog(
			"Are you sure?",
			isPresented: $isPresentingSaveConfirm,
			titleVisibility: .visible
		) {
			Button("Save") {
				onSave()
			}
		} message: {
			Text("Node will reboot after saving changes.")
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
