import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct TelemetryConfig: OptionsScreen {
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
	private var deviceUpdateInterval = 0
	@State
	private var environmentUpdateInterval = 0
	@State
	private var powerUpdateInterval = 0
	@State
	private var environmentMeasurementEnabled = false
	@State
	private var environmentScreenEnabled = false
	@State
	private var environmentDisplayFahrenheit = false
	@State
	private var powerMeasurementEnabled = false
	@State
	private var powerScreenEnabled = false
	@State
	private var hasChanges = false
	@State
	private var isPresentingSaveConfirm = false

	var body: some View {
		Form {
			Section(header: Text("Update Interval")) {
				Picker("Device metrics", selection: $deviceUpdateInterval ) {
					ForEach(UpdateIntervals.allCases) { ui in
						if ui.rawValue >= 900 {
							Text(ui.description)
						}
					}
				}
				.listRowSeparator(.hidden)

				Picker("Sensor metrics", selection: $environmentUpdateInterval ) {
					ForEach(UpdateIntervals.allCases) { ui in
						if ui.rawValue >= 900 {
							Text(ui.description)
						}
					}
				}
				.listRowSeparator(.hidden)
			}
			.headerProminence(.increased)

			Section(header: Text("Sensor Options")) {
				Text("Supported I2C Connected sensors will be detected automatically, sensors are BMP280, BME280, BME680, MCP9808, INA219, INA260, LPS22 and SHTC3.")
					.foregroundColor(.gray)
					.font(.callout)

				Toggle(isOn: $environmentMeasurementEnabled) {
					Text("Environment metrics")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $environmentScreenEnabled) {
					Text("Show on device screen")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $environmentDisplayFahrenheit) {
					Text("Fahrenheit")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
			.headerProminence(.increased)

			Section(header: Text("Power Options")) {
				Toggle(isOn: $powerMeasurementEnabled) {
					Label("Power metrics", systemImage: "bolt")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				.listRowSeparator(.visible)

				Picker("Update interval", selection: $powerUpdateInterval ) {
					ForEach(UpdateIntervals.allCases) { ui in
						if ui.rawValue >= 900 {
							Text(ui.description)
						}
					}
				}
				.listRowSeparator(.hidden)

				Toggle(isOn: $powerScreenEnabled) {
					Text("Power screen")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
			.headerProminence(.increased)
		}
		.disabled(connectedDevice.device == nil || node.telemetryConfig == nil)
		.navigationTitle("Telemetry Config")
		.navigationBarItems(
			trailing: SaveButton(node, changes: $hasChanges) {
				save()
			}
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsTelemetry.id, parameters: nil)
			setInitialValues()
		}
		.onChange(of: deviceUpdateInterval) {
			hasChanges = true
		}
		.onChange(of: environmentUpdateInterval) {
			hasChanges = true
		}
		.onChange(of: environmentMeasurementEnabled) {
			hasChanges = true
		}
		.onChange(of: environmentScreenEnabled) {
			hasChanges = true
		}
		.onChange(of: environmentDisplayFahrenheit) {
			hasChanges = true
		}
		.onChange(of: powerMeasurementEnabled) {
			hasChanges = true
		}
		.onChange(of: powerUpdateInterval) {
			hasChanges = true
		}
		.onChange(of: powerScreenEnabled) {
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
			node.telemetryConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestTelemetryConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.telemetryConfig {
			deviceUpdateInterval = Int(config.deviceUpdateInterval)
			environmentUpdateInterval = Int(config.environmentUpdateInterval)
			powerUpdateInterval = Int(config.powerUpdateInterval)

			environmentMeasurementEnabled = config.environmentMeasurementEnabled
			environmentScreenEnabled = config.environmentScreenEnabled
			environmentDisplayFahrenheit = config.environmentDisplayFahrenheit
			powerMeasurementEnabled = config.powerMeasurementEnabled
			powerScreenEnabled = config.powerScreenEnabled
		}
		else {
			deviceUpdateInterval = 1800
			environmentUpdateInterval = 1800
			powerUpdateInterval = 1800

			environmentMeasurementEnabled = false
			environmentScreenEnabled = false
			environmentDisplayFahrenheit = false
			powerMeasurementEnabled = false
			powerScreenEnabled = false
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

		var config = ModuleConfig.TelemetryConfig()
		config.deviceUpdateInterval = UInt32(deviceUpdateInterval)
		config.environmentUpdateInterval = UInt32(environmentUpdateInterval)
		config.environmentMeasurementEnabled = environmentMeasurementEnabled
		config.environmentScreenEnabled = environmentScreenEnabled
		config.environmentDisplayFahrenheit = environmentDisplayFahrenheit
		config.powerMeasurementEnabled = powerMeasurementEnabled
		config.powerUpdateInterval = UInt32(powerUpdateInterval)
		config.powerScreenEnabled = powerScreenEnabled

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveTelemetryConfig(
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
