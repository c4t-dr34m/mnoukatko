import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct DeviceConfig: OptionsScreen {
	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

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
	private var hasChanges = false
	@State
	private var deviceRole = 0
	@State
	private var buzzerGPIO = 0
	@State
	private var buttonGPIO = 0
	@State
	private var rebroadcastMode = 0
	@State
	private var nodeInfoBroadcastSecs = 10800
	@State
	private var doubleTapAsButtonPress = false
	@State
	private var ledHeartbeatEnabled = true
	@State
	private var isManaged = false
	@State
	private var tzdef = ""
	@State
	private var isPresentingNodeDBResetConfirm = false
	@State
	private var isPresentingFactoryResetConfirm = false

	var body: some View {
		VStack {
			Form {
				Section(header: Text("Options")) {
					VStack(alignment: .leading) {
						Picker("Device Role", selection: $deviceRole ) {
							ForEach(DeviceRoles.allCases) { dr in
								Text(dr.name)
							}
						}
						Text(DeviceRoles(rawValue: deviceRole)?.description ?? "")
							.foregroundColor(.gray)
							.font(.callout)
					}
					.pickerStyle(DefaultPickerStyle())

					VStack(alignment: .leading) {
						Picker("Rebroadcast Mode", selection: $rebroadcastMode ) {
							ForEach(RebroadcastModes.allCases) { rm in
								Text(rm.name)
							}
						}
						Text(RebroadcastModes(rawValue: rebroadcastMode)?.description ?? "")
							.foregroundColor(.gray)
							.font(.callout)
					}
					.pickerStyle(DefaultPickerStyle())

					Toggle(isOn: $isManaged) {
						Label("Managed Device", systemImage: "gearshape.arrow.triangle.2.circlepath")
						Text("Enabling Managed mode will restrict access to all radio configurations, such as short/long names, regions, channels, modules, etc. and will only be accessible through the Admin channel. To avoid being locked out, make sure the Admin channel is working properly before enabling it.")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					Picker("Node Info Broadcast Interval", selection: $nodeInfoBroadcastSecs ) {
						ForEach(UpdateIntervals.allCases) { ui in
							if ui.rawValue >= 3600 {
								Text(ui.description)
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
				}
				.headerProminence(.increased)

				Section(header: Text("Hardware")) {
					Toggle(isOn: $doubleTapAsButtonPress) {
						Label("Double Tap as Button", systemImage: "hand.tap")
						Text("Treat double tap on supported accelerometers as a user button press.")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					Toggle(isOn: $ledHeartbeatEnabled) {
						Label("LED Heartbeat", systemImage: "waveform.path.ecg")
						Text("Controls the blinking LED on the device.  For most devices this will control one of the up to 4 LEDS, the charger and GPS LEDs are not controllable.")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}
				.headerProminence(.increased)

				Section(header: Text("Debug")) {
					VStack(alignment: .leading) {
						HStack {
							Label("Time Zone", systemImage: "clock.badge.exclamationmark")

							TextField("Time Zone", text: $tzdef, axis: .vertical)
								.foregroundColor(.gray)
								.onChange(of: tzdef) {
									let totalBytes = tzdef.utf8.count
									// Only mess with the value if it is too big
									if totalBytes > 63 {
										tzdef = String(tzdef.dropLast())
									}
								}
								.foregroundColor(.gray)

						}
						.keyboardType(.default)
						.disableAutocorrection(true)

						Text("Time zone for dates on the device screen and log.")
							.foregroundColor(.gray)
							.font(.callout)
					}
				}
				.headerProminence(.increased)

				Section(header: Text("GPIO")) {
					Picker("Button GPIO", selection: $buttonGPIO) {
						ForEach(0 ..< 49) { gpio in
							if gpio == 0 {
								Text("Unset")
							}
							else {
								Text("Pin \(gpio)")
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())

					Picker("Buzzer GPIO", selection: $buzzerGPIO) {
						ForEach(0 ..< 49) { gpio in
							if gpio == 0 {
								Text("Unset")
							}
							else {
								Text("Pin \(gpio)")
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
				}
				.headerProminence(.increased)
			}
			.disabled(connectedDevice.device == nil || node.deviceConfig == nil)
			.navigationTitle("Device Config")
			.navigationBarItems(
				trailing: SaveButton(node, changes: $hasChanges) {
					save()
				}
			)
			.onAppear {
				Analytics.logEvent(AnalyticEvents.optionsDevice.id, parameters: nil)
				setInitialValues()
			}
			.onChange(of: deviceRole) {
				hasChanges = true
			}
			.onChange(of: buttonGPIO) {
				hasChanges = true
			}
			.onChange(of: buzzerGPIO) {
				hasChanges = true
			}
			.onChange(of: rebroadcastMode) {
				hasChanges = true
			}
			.onChange(of: nodeInfoBroadcastSecs) {
				hasChanges = true
			}
			.onChange(of: doubleTapAsButtonPress) {
				hasChanges = true
			}
			.onChange(of: isManaged) {
				hasChanges = true
			}
			.onChange(of: tzdef) {
				hasChanges = true
			}

			HStack {
				resetDatabasButton
				factoryResetButton
			}
		}
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.deviceConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestDeviceConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.deviceConfig {
			doubleTapAsButtonPress = config.doubleTapAsButtonPress
			ledHeartbeatEnabled = config.ledHeartbeatEnabled
			isManaged = config.isManaged
			tzdef = config.tzdef ?? ""
			deviceRole = Int(config.role)
			buttonGPIO = Int(config.buttonGpio)
			buzzerGPIO = Int(config.buzzerGpio)
			rebroadcastMode = Int(config.rebroadcastMode)
			nodeInfoBroadcastSecs = Int(config.nodeInfoBroadcastSecs)
		}
		else {
			doubleTapAsButtonPress = false
			ledHeartbeatEnabled = true
			isManaged = false
			tzdef = ""
			deviceRole = 0
			buttonGPIO = 0
			buzzerGPIO = 0
			rebroadcastMode = 0
			nodeInfoBroadcastSecs = 900
		}

		if nodeInfoBroadcastSecs < 3600 {
			nodeInfoBroadcastSecs = 3600
		}

		if tzdef.isEmpty {
			tzdef = TimeZone.current.posixDescription
			hasChanges = true
		}
		else {
			hasChanges = false
		}
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

		var config = Config.DeviceConfig()
		config.role = DeviceRoles(rawValue: deviceRole)!.protoEnumValue()
		config.buttonGpio = UInt32(buttonGPIO)
		config.buzzerGpio = UInt32(buzzerGPIO)
		config.rebroadcastMode = RebroadcastModes(rawValue: rebroadcastMode)?
			.protoEnumValue() ?? RebroadcastModes.all.protoEnumValue()
		config.nodeInfoBroadcastSecs = UInt32(nodeInfoBroadcastSecs)
		config.doubleTapAsButtonPress = doubleTapAsButtonPress
		config.isManaged = isManaged
		config.tzdef = tzdef
		config.ledHeartbeatDisabled = !ledHeartbeatEnabled

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveDeviceConfig(
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

	@ViewBuilder
	private var resetDatabasButton: some View {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		{
			Button("Reset NodeDB", role: .destructive) {
				isPresentingNodeDBResetConfirm = true
			}
			.disabled(node.user == nil)
			.buttonStyle(.bordered)
			.buttonBorderShape(.capsule)
			.controlSize(.large)
			.padding(.leading)
			.confirmationDialog(
				"Are you sure?",
				isPresented: $isPresentingNodeDBResetConfirm,
				titleVisibility: .visible
			) {
				Button("Erase all device and app data?", role: .destructive) {
					if nodeConfig.sendNodeDBReset(fromUser: fromUser, toUser: toUser) {
						DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
							bleManager.disconnectDevice()
							coreDataTools.clearCoreDataDatabase(context: context, includeRoutes: false)
						}
					}
					else {
						Logger.mesh.error("NodeDB Reset Failed")
					}
				}
			}
		}
	}

	@ViewBuilder
	private var factoryResetButton: some View {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		{
			Button("Factory Reset", role: .destructive) {
				isPresentingFactoryResetConfirm = true
			}
			.disabled(node.user == nil)
			.buttonStyle(.bordered)
			.buttonBorderShape(.capsule)
			.controlSize(.large)
			.padding(.trailing)
			.confirmationDialog(
				"Are you sure?",
				isPresented: $isPresentingFactoryResetConfirm,
				titleVisibility: .visible
			) {
				Button("Factory reset your device and app?", role: .destructive) {
					if nodeConfig.sendFactoryReset(fromUser: fromUser, toUser: toUser) {
						DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
							bleManager.disconnectDevice()
							coreDataTools.clearCoreDataDatabase(context: context, includeRoutes: false)
						}
					}
					else {
						Logger.mesh.error("Factory Reset Failed")
					}
				}
			}
		}
	}
}
