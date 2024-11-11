import FirebaseAnalytics
import MeshtasticProtobufs
import SwiftUI

struct PowerConfig: View {
	private let coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack

	let node: NodeInfoEntity

	@State private var isPowerSaving = false

	@State private var shutdownOnPowerLoss = false
	@State private var shutdownAfterSecs = 0
	@State private var adcOverride = false
	@State private var adcMultiplier: Float = 0.0

	@State private var waitBluetoothSecs = 60
	@State private var lsSecs = 300
	@State private var minWakeSecs = 10

	@State private var currentDevice: DeviceHardware?

	@State private var hasChanges: Bool = false
	@FocusState private var isFocused: Bool

	var body: some View {
		Form {
			Section {
				if
					currentDevice?.architecture == .esp32
						|| currentDevice?.architecture == .esp32S3
						|| (currentDevice?.architecture == .nrf52840 && (node.deviceConfig?.role ?? 0 == 5 || node.deviceConfig?.role ?? 0 == 6))
				{
					Toggle(isOn: $isPowerSaving) {
						Label("config.power.saving", systemImage: "bolt")
						Text("config.power.saving.description")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}

				Toggle(isOn: $shutdownOnPowerLoss) {
					Label("config.power.shutdown.on.power.loss", systemImage: "power")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				if shutdownOnPowerLoss {
					Picker("config.power.shutdown.after.secs", selection: $shutdownAfterSecs) {
						ForEach(UpdateIntervals.allCases) { at in
							Text(at.description)
						}
					}
					.pickerStyle(DefaultPickerStyle())
				}
			} header: {
				Text("config.power.settings")
			}

			if currentDevice?.architecture == .esp32 || currentDevice?.architecture == .esp32S3 {
				Section {
					Toggle(isOn: $adcOverride) {
						Text("config.power.adc.override")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					if adcOverride {
						HStack {
							Text("config.power.adc.multiplier")

							Spacer()

							FloatField(
								title: "config.power.adc.multiplier",
								number: $adcMultiplier
							) {
								(2.0 ... 6.0).contains($0)
							}
							.focused($isFocused)

							Spacer()
						}
					}
				} header: {
					Text("config.power.section.battery")
				}
			}
		}
		.disabled(connectedDevice.device == nil || node.powerConfig == nil)
		.navigationTitle("Power Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.toolbar {
			ToolbarItemGroup(placement: .keyboard) {
				Spacer()
				Button("dismiss.keyboard") {
					isFocused = false
				}
				.font(.subheadline)
			}
		}
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsPower.id, parameters: nil)

			Api().loadDeviceHardwareData { hw in
				for device in hw {
					let currentHardware = node.user?.hwModel ?? "UNSET"
					let deviceString = device.hwModelSlug.replacingOccurrences(of: "_", with: "")

					if deviceString == currentHardware {
						currentDevice = device
					}
				}
			}
			setPowerValues()

			// Need to request a Power config from the remote node before allowing changes
			if
				let device = connectedDevice.device,
				node.powerConfig == nil,
				let connectedNode = coreDataTools.getNodeInfo(
					id: device.num ?? 0,
					context: context
				)
			{
				nodeConfig.requestPowerConfig(
					fromUser: connectedNode.user!,
					toUser: node.user!,
					adminIndex: connectedNode.myInfo?.adminIndex ?? 0)
			}
		}
		.onChange(of: isPowerSaving) {
			hasChanges = true
		}
		.onChange(of: shutdownOnPowerLoss) {
			hasChanges = true
		}
		.onChange(of: shutdownAfterSecs) {
			hasChanges = true
		}
		.onChange(of: adcOverride) {
			hasChanges = true
		}
		.onChange(of: adcMultiplier) {
			hasChanges = true
		}
		.onChange(of: waitBluetoothSecs) {
			hasChanges = true
		}
		.onChange(of: lsSecs) {
			hasChanges = true
		}
		.onChange(of: minWakeSecs) {
			hasChanges = true
		}

		SaveConfigButton(node: node, hasChanges: $hasChanges) {
			guard
				let device = connectedDevice.device,
				let connectedNode = coreDataTools.getNodeInfo(
					id: device.num,
					context: context
				),
				let fromUser = connectedNode.user,
				let toUser = node.user
			else {
				return
			}

			var config = Config.PowerConfig()
			config.isPowerSaving = isPowerSaving
			config.onBatteryShutdownAfterSecs = shutdownOnPowerLoss ? UInt32(shutdownAfterSecs) : 0
			config.adcMultiplierOverride = adcOverride ? adcMultiplier : 0
			config.waitBluetoothSecs = UInt32(waitBluetoothSecs)
			config.lsSecs = UInt32(lsSecs)
			config.minWakeSecs = UInt32(minWakeSecs)

			let adminMessageId = nodeConfig.savePowerConfig(
				config: config,
				fromUser: fromUser,
				toUser: toUser,
				adminIndex: connectedNode.myInfo?.adminIndex ?? 0
			)
			if adminMessageId > 0 {
				// Should show a saved successfully alert once I know that to be true
				// for now just disable the button after a successful save
				hasChanges = false
				goBack()
			}
		}
	}

	private func setPowerValues() {
		if let config = node.powerConfig {
			isPowerSaving = config.isPowerSaving
			adcMultiplier = config.adcMultiplierOverride
			adcOverride = adcMultiplier != 0
			shutdownAfterSecs = Int(config.onBatteryShutdownAfterSecs)
			shutdownOnPowerLoss = shutdownAfterSecs != 0
			waitBluetoothSecs = Int(config.waitBluetoothSecs)
			lsSecs = Int(config.lsSecs)
			minWakeSecs = Int(config.minWakeSecs)
		}
		else {
			adcOverride = adcMultiplier != 0
			shutdownOnPowerLoss = shutdownAfterSecs != 0
		}
	}
}

/// Helper view for isolating user float input that can be validated before being applied.
private struct FloatField: View {
	let title: String

	@Binding
	var number: Float

	var isValid: (Float) -> Bool = { _ in true }

	@State
	private var typingNumber: Float = 0.0

	var body: some View {
		TextField(title.localized, value: $typingNumber, format: .number)
			.keyboardType(.decimalPad)
			.foregroundColor(.gray)
			.multilineTextAlignment(.trailing)
			.onChange(of: typingNumber, initial: true) {
				if isValid(typingNumber) {
					number = typingNumber
				}
				else {
					typingNumber = number
				}
			}
	}
}
