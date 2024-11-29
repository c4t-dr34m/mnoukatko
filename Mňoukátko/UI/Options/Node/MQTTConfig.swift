/*
Mňoukátko - the Meshtastic® client

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
import CoreLocation
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct MQTTConfig: OptionsScreen {
	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	private let locale = Locale.current

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleManager: BLEManager
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@State
	private var isPresentingSaveConfirm = false
	@State
	private var hasChanges = false
	@State
	private var enabled = false
	@State
	private var proxyToClientEnabled = false
	@State
	private var address = ""
	@State
	private var username = ""
	@State
	private var password = ""
	@State
	private var encryptionEnabled = true
	@State
	private var jsonEnabled = false
	@State
	private var tlsEnabled = true
	@State
	private var root = "msh"
	@State
	private var mqttConnected = false
	@State
	private var defaultTopic = "msh"
	@State
	private var mapReportingEnabled = false
	@State
	private var mapPublishIntervalSecs = 3600
	@State
	private var preciseLocation = false
	@State
	private var mapPositionPrecision: Double = 13.0

	@ViewBuilder
	var body: some View {
		Form {
			if
				let loraConfig = node.loRaConfig,
				let dutyCycle = RegionCodes(rawValue: Int(loraConfig.regionCode))?.dutyCycle,
				dutyCycle > 0, dutyCycle < 100
			{
				HStack(alignment: .center) {
					Image(systemName: "exclamationmark.triangle")
						.font(.system(size: 32, weight: .semibold))
						.foregroundColor(.orange)

					Text("Your region has a \(dutyCycle)% duty cycle. MQTT is not advised when your duty cycle is restricted as the extra traffic may quickly overwhelm your LoRa mesh.")
						.font(.body)
				}
			}

			Section(header: Text("Options")) {
				Toggle(isOn: $enabled) {
					Text("MQTT")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: enabled) {
					hasChanges = true
				}

				Toggle(isOn: $encryptionEnabled) {
					Text("Encryption")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $proxyToClientEnabled) {
					Text("Use mobile data")
						.font(.body)
						.strikethrough(jsonEnabled)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.disabled(jsonEnabled)
				.onChange(of: proxyToClientEnabled) {
					if proxyToClientEnabled {
						jsonEnabled = false
					}

					hasChanges = true
				}

				Toggle(isOn: $jsonEnabled) {
					Text("JSON")
						.font(.body)
						.strikethrough(proxyToClientEnabled)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.disabled(proxyToClientEnabled)
				.onChange(of: jsonEnabled) {
					if jsonEnabled {
						proxyToClientEnabled = false
					}

					hasChanges = true
				}
			}
			.headerProminence(.increased)

			Section(header: Text("Map Report")) {
				Toggle(isOn: $mapReportingEnabled) {
					Text("Map report")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: mapReportingEnabled) {
					hasChanges = true
				}

				if mapReportingEnabled {
					Picker("Publish interval", selection: $mapPublishIntervalSecs ) {
						ForEach(UpdateIntervals.allCases) { ui in
							if ui.rawValue >= 3600 {
								Text(ui.description)
							}
						}
					}
					.onChange(of: mapPublishIntervalSecs) {
						hasChanges = true
					}

					Toggle(isOn: $preciseLocation) {
						Text("Precise location")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.onChange(of: preciseLocation) {
						if preciseLocation == false {
							mapPositionPrecision = 12
						}
						else {
							mapPositionPrecision = 32
						}

						hasChanges = true
					}

					if !preciseLocation {
						VStack(alignment: .leading) {
							Text("Approximate location")
								.font(.body)

							Slider(value: $mapPositionPrecision, in: 11...16, step: 1) {
							} minimumValueLabel: {
								Image(systemName: "minus")
							} maximumValueLabel: {
								Image(systemName: "plus")
							}

							Text(PositionPrecision(rawValue: Int(mapPositionPrecision))?.description ?? "")
								.foregroundColor(.gray)
								.font(.callout)
						}
					}
				}
			}
			.headerProminence(.increased)

			Section(header: Text("Root Topic")) {
				HStack {
					Text("Root topic")
						.font(.body)

					Spacer()

					TextField("", text: $root)
						.optionsStyle()
						.keyboardType(.asciiCapable)
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.onChange(of: root) {
							if root.utf8.count > 30 {
								root = String(root.dropLast())
							}

							hasChanges = true
						}
				}
			}
			.headerProminence(.increased)

			Section(header: Text("Server")) {
				HStack {
					Text("Address")
						.font(.body)

					Spacer()

					TextField("", text: $address)
						.optionsStyle()
						.keyboardType(.default)
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.onChange(of: address) {
							if address.utf8.count > 62 {
								address = String(address.dropLast())
							}

							hasChanges = true
						}
				}

				HStack {
					Text("Username")
						.font(.body)

					Spacer()

					TextField("", text: $username)
						.optionsStyle()
						.keyboardType(.default)
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.onChange(of: username) {
							if username.utf8.count > 62 {
								username = String(username.dropLast())
							}

							hasChanges = true
						}
				}
				.scrollDismissesKeyboard(.interactively)

				HStack {
					Text("Password")
						.font(.body)

					Spacer()

					TextField("", text: $password)
						.optionsStyle()
						.keyboardType(.default)
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.onChange(of: password) {
							if password.utf8.count > 62 {
								password = String(password.dropLast())
							}

							hasChanges = true
						}
				}

				Toggle(isOn: $tlsEnabled) {
					Text("TLS")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.onChange(of: tlsEnabled) {
					hasChanges = true
				}
			}
			.headerProminence(.increased)
		}
		.scrollDismissesKeyboard(.interactively)
		.disabled(connectedDevice.device == nil || node.mqttConfig == nil)
		.navigationTitle("MQTT Config")
		.navigationBarItems(
			trailing: SaveButton(changes: $hasChanges) {
				save()
			}
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsMQTT.id, parameters: nil)
			setInitialValues()
		}
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.mqttConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestMQTTConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if mapPositionPrecision == 0 {
			mapPositionPrecision = 12
		}
		preciseLocation = mapPositionPrecision == 32

		if let config = node.mqttConfig {
			enabled = config.enabled
			proxyToClientEnabled = config.proxyToClientEnabled

			address = config.address ?? ""
			username = config.username ?? ""
			password = config.password ?? ""
			root = config.root ?? "msh"

			encryptionEnabled = config.encryptionEnabled
			jsonEnabled = config.jsonEnabled
			tlsEnabled = config.tlsEnabled
			mapReportingEnabled = config.mapReportingEnabled
			mapPublishIntervalSecs = Int(config.mapPublishIntervalSecs)
			mapPositionPrecision = Double(config.mapPositionPrecision)
		}
		else {
			enabled = false
			proxyToClientEnabled = false

			address = ""
			username = ""
			password = ""
			root = "msh"

			encryptionEnabled = false
			jsonEnabled = false
			tlsEnabled = false
			mapReportingEnabled = false
			mapPublishIntervalSecs = Int(3600)
			mapPositionPrecision = Double(12)
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

		var config = ModuleConfig.MQTTConfig()
		config.enabled = enabled
		config.proxyToClientEnabled = proxyToClientEnabled
		config.address = address
		config.username = username
		config.password = password
		config.root = root
		config.encryptionEnabled = encryptionEnabled
		config.jsonEnabled = jsonEnabled
		config.tlsEnabled = tlsEnabled
		config.mapReportingEnabled = mapReportingEnabled
		config.mapReportSettings.positionPrecision = UInt32(mapPositionPrecision)
		config.mapReportSettings.publishIntervalSecs = UInt32(mapPublishIntervalSecs)

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveMQTTConfig(
				config: config,
				fromUser: fromUser,
				toUser: toUser,
				adminIndex: adminIndex
			) > 0
		{
			hasChanges = false

			if config.enabled, let config = node.mqttConfig {
				bleManager.connectMQTT(config: config)
			}
			else {
				bleManager.disconnectMQTT()
			}

			goBack()
		}
	}
}
