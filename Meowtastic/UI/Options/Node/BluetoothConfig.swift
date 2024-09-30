import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct BluetoothConfig: View {
	private let node: NodeInfoEntity
	private let coreDataTools = CoreDataTools()
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
					Text("Fixed PIN")

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
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsBluetooth.id, parameters: nil)
		}

		SaveConfigButton(node: node, hasChanges: $hasChanges) {
			if
				let myNodeNum = connectedDevice.device?.num,
				let connectedNode = coreDataTools.getNodeInfo(id: myNodeNum, context: context)
			{
				var bc = Config.BluetoothConfig()
				bc.enabled = enabled
				bc.mode = BluetoothModes(rawValue: mode)?.protoEnumValue() ?? Config.BluetoothConfig.PairingMode.randomPin
				bc.fixedPin = UInt32(fixedPin) ?? 123456
				bc.deviceLoggingEnabled = deviceLoggingEnabled

				let adminMessageId = nodeConfig.saveBluetoothConfig(
					config: bc,
					fromUser: connectedNode.user!,
					toUser: node.user!,
					adminIndex: connectedNode.myInfo?.adminIndex ?? 0
				)

				if adminMessageId > 0 {
					hasChanges = false
					goBack()
				}
			}
		}
		.onAppear {
			setInitialValues()

			if let device = connectedDevice.device, node.bluetoothConfig == nil {
				if let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context) {
					nodeConfig.requestBluetoothConfig(
						fromUser: connectedNode.user!,
						toUser: node.user!,
						adminIndex: connectedNode.myInfo?.adminIndex ?? 0
					)
				}
			}
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
		.navigationTitle("Bluetooth Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
	}

	init(node: NodeInfoEntity) {
		self.node = node
	}

	private func setInitialValues() {
		if let config = node.bluetoothConfig {
			enabled = config.enabled
			mode = Int(config.mode)
			fixedPin = String(config.fixedPin)
			deviceLoggingEnabled = config.deviceLoggingEnabled
		}
		else {
			enabled = true
			mode = 0
			fixedPin = "123456"
			deviceLoggingEnabled = false

		}

		hasChanges = false
	}
}
