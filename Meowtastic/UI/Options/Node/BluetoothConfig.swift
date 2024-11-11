import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct BluetoothConfig: OptionsScreen {
	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	private let numberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .none

		return formatter
	}()

	private var pinLength: Int = 6
	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@State
	private var hasChanges = false
	@State
	private var enabled = true
	@State
	private var mode = 0
	@State
	private var fixedPin = "123456"
	@State
	private var shortPin = false
	@State
	private var deviceLoggingEnabled = false

	@ViewBuilder
	var body: some View {
		Form {
			Toggle(isOn: $enabled) {
				Text("Bluetooth")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Picker("Pairing Mode", selection: $mode) {
				ForEach(BluetoothModes.allCases) { bm in
					Text(bm.description)
				}
			}
			.pickerStyle(DefaultPickerStyle())

			if mode == 1 {
				HStack {
					Text("Fixed PIN:")
					Spacer()
					TextField("Fixed PIN", text: $fixedPin)
						.foregroundColor(.gray)
						.onChange(of: fixedPin) {
							// Don't let the first character be 0 because it will get stripped when saving a UInt32
							if fixedPin.first == "0" {
								fixedPin = fixedPin.replacing("0", with: "")
							}

							// Require that pin is no more than 6 numbers and no less than 6 numbers
							if fixedPin.utf8.count == pinLength {
								shortPin = false
							}
							else if fixedPin.utf8.count > pinLength {
								shortPin = false
								fixedPin = String(fixedPin.prefix(pinLength))
							}
							else if fixedPin.utf8.count < pinLength {
								shortPin = true
							}
						}
						.foregroundColor(.gray)
				}
				.keyboardType(.decimalPad)

				if shortPin {
					Text("PIN must be 6 digits long")
						.font(.callout)
						.foregroundColor(.red)
				}
			}

			Toggle(isOn: $deviceLoggingEnabled) {
				Text("Device Logging")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))
		}
		.disabled(connectedDevice.device == nil || node.bluetoothConfig == nil)
		.navigationTitle("Bluetooth Config")
		.navigationBarItems(
			trailing: SaveButton(node, changes: $hasChanges) {
				save()
			}
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsBluetooth.id, parameters: nil)
			setInitialValues()
		}
		.onChange(of: enabled) {
			hasChanges = true
		}
		.onChange(of: mode) {
			hasChanges = true
		}
		.onChange(of: fixedPin) {
			hasChanges = true
		}
		.onChange(of: deviceLoggingEnabled) {
			hasChanges = true
		}
	}

	init(node: NodeInfoEntity) {
		self.node = node
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.securityConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestBluetoothConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.bluetoothConfig {
			enabled = config.enabled
			mode = Int(config.mode)
			fixedPin = String(config.fixedPin)
		}
		else {
			enabled = true
			mode = 0
			fixedPin = "123456"
		}

		hasChanges = false
	}

	func save() {
		guard
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		else {
			return
		}

		var config = Config.BluetoothConfig()
		config.enabled = enabled
		config.mode = BluetoothModes(rawValue: mode)?.protoEnumValue() ?? Config.BluetoothConfig.PairingMode.randomPin
		config.fixedPin = UInt32(fixedPin) ?? 123456

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveBluetoothConfig(
				config: config,
				fromUser: fromUser,
				toUser: toUser,
				adminIndex: adminIndex
			) > 0
		{
			hasChanges = false
			goBack()
		}
	}
}
