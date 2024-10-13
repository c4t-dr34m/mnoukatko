import MeshtasticProtobufs
import OSLog
import SwiftUI

struct TelemetryConfig: View {
	var node: NodeInfoEntity

	private let coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleManager: BLEManager
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack

	@State private var deviceUpdateInterval = 0
	@State private var environmentUpdateInterval = 0
	@State private var powerUpdateInterval = 0
	@State private var environmentMeasurementEnabled = false
	@State private var environmentScreenEnabled = false
	@State private var environmentDisplayFahrenheit = false
	@State private var powerMeasurementEnabled = false
	@State private var powerScreenEnabled = false
	@State private var hasChanges = false
	@State private var isPresentingSaveConfirm: Bool = false

	var body: some View {
		VStack {
			Form {
				ConfigHeader(
					title: "Telemetry",
					config: \.telemetryConfig,
					node: node
				)

				Section(header: Text("Update Interval")) {
					Picker("Device Metrics", selection: $deviceUpdateInterval ) {
						ForEach(UpdateIntervals.allCases) { ui in
							if ui.rawValue >= 900 {
								Text(ui.description)
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
					.listRowSeparator(.hidden)

					Text("How often device metrics are sent out over the mesh. Default is 30 minutes.")
						.foregroundColor(.gray)
						.font(.callout)
						.listRowSeparator(.visible)

					Picker("Sensor Metrics", selection: $environmentUpdateInterval ) {
						ForEach(UpdateIntervals.allCases) { ui in
							if ui.rawValue >= 900 {
								Text(ui.description)
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
					.listRowSeparator(.hidden)

					Text("How often sensor metrics are sent out over the mesh. Default is 30 minutes.")
						.foregroundColor(.gray)
						.font(.callout)
				}

				Section(header: Text("Sensor Options")) {
					Text("Supported I2C Connected sensors will be detected automatically, sensors are BMP280, BME280, BME680, MCP9808, INA219, INA260, LPS22 and SHTC3.")
						.foregroundColor(.gray)
						.font(.callout)

					Toggle(isOn: $environmentMeasurementEnabled) {
						Label("enabled", systemImage: "chart.xyaxis.line")
					}
					.toggleStyle(SwitchToggleStyle(tint: .meowOrange))

					Toggle(isOn: $environmentScreenEnabled) {
						Label("Show on device screen", systemImage: "display")
					}
					.toggleStyle(SwitchToggleStyle(tint: .meowOrange))

					Toggle(isOn: $environmentDisplayFahrenheit) {
						Label("Display Fahrenheit", systemImage: "thermometer")
					}
					.toggleStyle(SwitchToggleStyle(tint: .meowOrange))
				}

				Section(header: Text("Power Options")) {
					Toggle(isOn: $powerMeasurementEnabled) {
						Label("enabled", systemImage: "bolt")
					}
					.toggleStyle(SwitchToggleStyle(tint: .meowOrange))
					.listRowSeparator(.visible)

					Picker("Power Metrics", selection: $powerUpdateInterval ) {
						ForEach(UpdateIntervals.allCases) { ui in
							if ui.rawValue >= 900 {
								Text(ui.description)
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
					.listRowSeparator(.hidden)

					Text("How often power metrics are sent out over the mesh. Default is 30 minutes.")
						.foregroundColor(.gray)
						.font(.callout)
					.listRowSeparator(.visible)

					Toggle(isOn: $powerScreenEnabled) {
						Label("Power Screen", systemImage: "tv")
					}
					.toggleStyle(SwitchToggleStyle(tint: .meowOrange))
				}
			}
			.disabled(
				bleManager.getConnectedDevice() == nil || node.telemetryConfig == nil
			)

			SaveConfigButton(node: node, hasChanges: $hasChanges) {
				if
					let device = bleManager.getConnectedDevice(),
					let connectedNode = coreDataTools.getNodeInfo(
						id: device.num,
						context: context
					)
				{
					var tc = ModuleConfig.TelemetryConfig()
					tc.deviceUpdateInterval = UInt32(deviceUpdateInterval)
					tc.environmentUpdateInterval = UInt32(environmentUpdateInterval)
					tc.environmentMeasurementEnabled = environmentMeasurementEnabled
					tc.environmentScreenEnabled = environmentScreenEnabled
					tc.environmentDisplayFahrenheit = environmentDisplayFahrenheit
					tc.powerMeasurementEnabled = powerMeasurementEnabled
					tc.powerUpdateInterval = UInt32(powerUpdateInterval)
					tc.powerScreenEnabled = powerScreenEnabled

					let adminMessageId = nodeConfig.saveTelemetryConfig(
						config: tc,
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
				setTelemetryValues()

				// Need to request a TelemetryModuleConfig from the remote node before allowing changes
				if
					let peripheral = bleManager.getConnectedDevice(),
					let connectedNode = coreDataTools.getNodeInfo(id: peripheral.num, context: context),
					node.telemetryConfig == nil
				{
					nodeConfig.requestTelemetryConfig(
						fromUser: connectedNode.user!,
						toUser: node.user!,
						adminIndex: connectedNode.myInfo?.adminIndex ?? 0
					)
				}
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
			.navigationTitle("Telemetry Config")
			.navigationBarItems(
				trailing: ConnectionInfo()
			)
		}
	}

	func setTelemetryValues() {
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
			deviceUpdateInterval = Int(1800)
			environmentUpdateInterval = Int(1800)
			powerUpdateInterval = Int(1800)

			environmentMeasurementEnabled = false
			environmentScreenEnabled = false
			environmentDisplayFahrenheit = false
			powerMeasurementEnabled = false
			powerScreenEnabled = false
		}

		hasChanges = false
	}
}
