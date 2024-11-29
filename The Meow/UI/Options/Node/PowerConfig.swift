/*
The Meow - the Meshtastic® client

Copyright © 2022-2024 Garth Vander Houwen
Copyright © 2024 Radovan Paška

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
import FirebaseAnalytics
import MeshtasticProtobufs
import SwiftUI

struct PowerConfig: OptionsScreen {
	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@State
	private var isPowerSaving = false
	@State
	private var shutdownOnPowerLoss = false
	@State
	private var shutdownAfterSecs = 0
	@State
	private var adcOverride = false
	@State
	private var adcMultiplier: Float = 0.0
	@State
	private var waitBluetoothSecs = 60
	@State
	private var lsSecs = 300
	@State
	private var minWakeSecs = 10
	@State
	private var currentDevice: DeviceHardware?
	@State
	private var hasChanges: Bool = false
	@FocusState
	private var isFocused: Bool

	var body: some View {
		Form {
			Section(header: Text("Power")) {
				if
					currentDevice?.architecture == .esp32
						|| currentDevice?.architecture == .esp32S3
						|| (currentDevice?.architecture == .nrf52840 && (node.deviceConfig?.role ?? 0 == 5 || node.deviceConfig?.role ?? 0 == 6))
				{
					Toggle(isOn: $isPowerSaving) {
						Text("Power saving")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}

				Toggle(isOn: $shutdownOnPowerLoss) {
					Text("Shutdown on power loss")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				if shutdownOnPowerLoss {
					Picker("Shutdown after", selection: $shutdownAfterSecs) {
						ForEach(UpdateIntervals.allCases) { at in
							Text(at.description)
						}
					}
				}
			}
			.headerProminence(.increased)

			if currentDevice?.architecture == .esp32 || currentDevice?.architecture == .esp32S3 {
				Section(header: Text("Battery")) {
					Toggle(isOn: $adcOverride) {
						Text("ADC override")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					if adcOverride {
						HStack {
							Text("ADC multiplier")
								.font(.body)

							Spacer()

							FloatField(
								title: "Multiplier",
								number: $adcMultiplier
							) {
								(2.0 ... 6.0).contains($0)
							}
							.focused($isFocused)
						}
					}
				}
				.headerProminence(.increased)
			}
		}
		.disabled(connectedDevice.device == nil || node.powerConfig == nil)
		.navigationTitle("Power Config")
		.navigationBarItems(
			trailing: SaveButton(changes: $hasChanges) {
				save()
			}
		)
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

			setInitialValues()
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
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.powerConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestPowerConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

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

		var config = Config.PowerConfig()
		config.isPowerSaving = isPowerSaving
		config.onBatteryShutdownAfterSecs = shutdownOnPowerLoss ? UInt32(shutdownAfterSecs) : 0
		config.adcMultiplierOverride = adcOverride ? adcMultiplier : 0
		config.waitBluetoothSecs = UInt32(waitBluetoothSecs)
		config.lsSecs = UInt32(lsSecs)
		config.minWakeSecs = UInt32(minWakeSecs)

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.savePowerConfig(
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
			.optionsStyle()
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
