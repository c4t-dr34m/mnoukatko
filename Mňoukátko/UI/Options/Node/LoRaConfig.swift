/*
Mňoukátko - a Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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
import CoreData
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct LoRaConfig: OptionsScreen {
	enum Field: Hashable {
		case channelNum
		case frequencyOverride
	}

	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	private let formatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.groupingSeparator = ""

		return formatter
	}()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@FocusState
	private var focusedField: Field?
	@State
	private var hasChanges = false
	@State
	private var region = 0
	@State
	private var modemPreset = 0
	@State
	private var hopLimit = 3
	@State
	private var txPower = 0
	@State
	private var txEnabled = true
	@State
	private var usePreset = true
	@State
	private var channelNum = 0
	@State
	private var bandwidth = 0
	@State
	private var spreadFactor = 0
	@State
	private var codingRate = 0
	@State
	private var rxBoostedGain = false
	@State
	private var overrideFrequency: Float = 0.0
	@State
	private var ignoreMqtt = false

	let floatFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		return formatter
	}()

	@ViewBuilder
	var body: some View {
		Form {
			sectionOptions
			sectionAdvanced
		}
		.disabled(connectedDevice.device == nil || node.loRaConfig == nil)
		.navigationTitle("LoRa Config")
		.navigationBarItems(
			trailing: SaveButton(changes: $hasChanges) {
				save()
			}
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsLoRa.id, parameters: nil)
			setInitialValues()
		}
		.onChange(of: region) {
			hasChanges = true
		}
		.onChange(of: usePreset) {
			hasChanges = true
		}
		.onChange(of: modemPreset) {
			hasChanges = true
		}
		.onChange(of: hopLimit) {
			hasChanges = true
		}
		.onChange(of: channelNum) {
			hasChanges = true
		}
		.onChange(of: bandwidth) {
			hasChanges = true
		}
		.onChange(of: codingRate) {
			hasChanges = true
		}
		.onChange(of: spreadFactor) {
			hasChanges = true
		}
		.onChange(of: rxBoostedGain) {
			hasChanges = true
		}
		.onChange(of: overrideFrequency) {
			hasChanges = true
		}
		.onChange(of: txPower) {
			hasChanges = true
		}
		.onChange(of: txEnabled) {
			hasChanges = true
		}
		.onChange(of: ignoreMqtt) {
			hasChanges = true
		}
	}

	@ViewBuilder
	private var sectionOptions: some View {
		Section(header: Text("Options")) {
			Picker("Region", selection: $region) {
				ForEach(RegionCodes.allCases) { region in
					Text(region.description)
				}
			}

			Toggle(isOn: $usePreset) {
				Text("Use preset")
					.font(.body)
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			if usePreset {
				Picker("Presets", selection: $modemPreset ) {
					ForEach(ModemPresets.allCases) { m in
						Text(m.description)
					}
				}
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	private var sectionAdvanced: some View {
		Section(header: Text("Advanced")) {
			Toggle(isOn: $ignoreMqtt) {
				Text("Ignore MQTT")
					.font(.body)
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Toggle(isOn: $txEnabled) {
				Text("Transmit")
					.font(.body)
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			if !usePreset {
				Picker("Bandwidth", selection: $bandwidth) {
					ForEach(Bandwidths.allCases) { bw in
						Text(bw.description)
							.tag(bw.rawValue == 250 ? 0 : bw.rawValue)
					}
				}

				Picker("Spread factor", selection: $spreadFactor) {
					ForEach(7..<13) {
						Text("\($0)")
							.tag($0 == 12 ? 0 : $0)
					}
				}

				Picker("Coding rate", selection: $codingRate) {
					ForEach(5..<9) {
						Text("\($0)")
							.tag($0 == 8 ? 0 : $0)
					}
				}
			}

			Picker("Number of hops", selection: $hopLimit) {
				ForEach(0..<8) {
					Text("\($0)")
						.tag($0)
				}
			}

			VStack(alignment: .leading) {
				HStack {
					Text("Frequency slot")
						.fixedSize()

					Spacer()

					TextField("", value: $channelNum, formatter: formatter)
						.optionsStyle()
						.keyboardType(.decimalPad)
						.focused($focusedField, equals: .channelNum)
						.disabled(overrideFrequency > 0.0)
				}

				Text("This determines the actual frequency you are transmitting on in the band. If set to 0 this value will be calculated automatically based on the primary channel name.")
					.foregroundColor(.gray)
					.font(.callout)
			}

			Toggle(isOn: $rxBoostedGain) {
				Text("Rx boosted gain")
					.font(.body)

			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			HStack {
				Text("Frequency override")
					.font(.body)

				Spacer()

				TextField("", value: $overrideFrequency, formatter: floatFormatter)
					.optionsStyle()
					.keyboardType(.decimalPad)
					.focused($focusedField, equals: .frequencyOverride)
			}

			Stepper(
				"\(txPower) dBm transmit power",
				value: $txPower,
				in: 1...30,
				step: 1
			)
			.padding(5)
		}
		.headerProminence(.increased)
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.loRaConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestLoRaConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.loRaConfig {
			hopLimit = Int(config.hopLimit)
			region = Int(config.regionCode)
			usePreset = config.usePreset
			modemPreset = Int(config.modemPreset)
			txEnabled = config.txEnabled
			txPower = Int(config.txPower)
			channelNum = Int(config.channelNum)
			bandwidth = Int(config.bandwidth)
			codingRate = Int(config.codingRate)
			spreadFactor = Int(config.spreadFactor)
			rxBoostedGain = config.sx126xRxBoostedGain
			overrideFrequency = config.overrideFrequency
			ignoreMqtt = config.ignoreMqtt
		}
		else {
			hopLimit = 3
			region = 0
			usePreset = true
			modemPreset = 0
			txEnabled = true
			txPower = 0
			channelNum = 0
			bandwidth = 0
			codingRate = 0
			spreadFactor = 0
			rxBoostedGain = false
			overrideFrequency = 0.0
			ignoreMqtt = false
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

		// swiftlint:disable force_unwrapping
		var config = Config.LoRaConfig()
		config.hopLimit = UInt32(hopLimit)
		config.region = RegionCodes(rawValue: region)!.protoEnumValue()
		config.modemPreset = ModemPresets(rawValue: modemPreset)!.protoEnumValue()
		config.usePreset = usePreset
		config.txEnabled = txEnabled
		config.txPower = Int32(txPower)
		config.channelNum = UInt32(channelNum)
		config.bandwidth = UInt32(bandwidth)
		config.codingRate = UInt32(codingRate)
		config.spreadFactor = UInt32(spreadFactor)
		config.sx126XRxBoostedGain = rxBoostedGain
		config.overrideFrequency = overrideFrequency
		config.ignoreMqtt = ignoreMqtt
		// swiftlint:enable force_unwrapping

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveLoRaConfig(
				config: config,
				fromUser: fromUser,
				toUser: toUser,
				adminIndex: adminIndex
			) > 0
		{
			UserDefaults.modemPreset = modemPreset
			hasChanges = false
			goBack()
		}
	}
}
