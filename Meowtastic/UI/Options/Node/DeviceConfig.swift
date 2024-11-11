//
//  DeviceConfig.swift
//  Meshtastic Apple
//
//  Copyright (c) Garth Vander Houwen 6/13/22.
//
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct DeviceConfig: View {

	private let coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleManager: BLEManager
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack

	var node: NodeInfoEntity

	@State
	var hasChanges = false
	@State
	var deviceRole = 0
	@State
	var buzzerGPIO = 0
	@State
	var buttonGPIO = 0
	@State
	var rebroadcastMode = 0
	@State
	var nodeInfoBroadcastSecs = 10800
	@State
	var doubleTapAsButtonPress = false
	@State
	var ledHeartbeatEnabled = true
	@State
	var isManaged = false
	@State
	var tzdef = ""
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

				Section(header: Text("Debug")) {
					VStack(alignment: .leading) {
						HStack {
							Label("Time Zone", systemImage: "clock.badge.exclamationmark")

							TextField("Time Zone", text: $tzdef, axis: .vertical)
								.foregroundColor(.gray)
								.onChange(of: tzdef, perform: { _ in
									let totalBytes = tzdef.utf8.count
									// Only mess with the value if it is too big
									if totalBytes > 63 {
										tzdef = String(tzdef.dropLast())
									}
								})
								.foregroundColor(.gray)

						}
						.keyboardType(.default)
						.disableAutocorrection(true)
						Text("Time zone for dates on the device screen and log.")
							.foregroundColor(.gray)
							.font(.callout)
					}
				}
				Section(header: Text("GPIO")) {
					Picker("Button GPIO", selection: $buttonGPIO) {
						ForEach(0..<49) {
							if $0 == 0 {
								Text("unset")
							} else {
								Text("Pin \($0)")
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
					Picker("Buzzer GPIO", selection: $buzzerGPIO) {
						ForEach(0..<49) {
							if $0 == 0 {
								Text("unset")
							}
							else {
								Text("Pin \($0)")
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())
				}
			}
			.disabled(bleManager.getConnectedDevice() == nil || node.deviceConfig == nil)
			// Only show these buttons for the BLE connected node

			if
				let connectedDevice = bleManager.getConnectedDevice(),
				node.num ?? -1 == connectedDevice.num
			{
				HStack {
					Button("Reset NodeDB", role: .destructive) {
						isPresentingNodeDBResetConfirm = true
					}
					.disabled(node.user == nil)
					.buttonStyle(.bordered)
					.buttonBorderShape(.capsule)
					.controlSize(.large)
					.padding(.leading)
					.confirmationDialog(
						"are.you.sure",
						isPresented: $isPresentingNodeDBResetConfirm,
						titleVisibility: .visible
					) {
						Button("Erase all device and app data?", role: .destructive) {
							if nodeConfig.sendNodeDBReset(fromUser: node.user!, toUser: node.user!) {
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
					Button("Factory Reset", role: .destructive) {
						isPresentingFactoryResetConfirm = true
					}
					.disabled(node.user == nil)
					.buttonStyle(.bordered)
					.buttonBorderShape(.capsule)
					.controlSize(.large)
					.padding(.trailing)
					.confirmationDialog(
						"All device and app data will be deleted. You will also need to forget your devices under Settings > Bluetooth.",
						isPresented: $isPresentingFactoryResetConfirm,
						titleVisibility: .visible
					) {
						Button("Factory reset your device and app? ", role: .destructive) {
							if nodeConfig.sendFactoryReset(fromUser: node.user!, toUser: node.user!) {
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
			HStack {
				SaveConfigButton(node: node, hasChanges: $hasChanges) {
					if
						let connectedDevice = bleManager.getConnectedDevice(),
						let connectedNode = coreDataTools.getNodeInfo(
							id: connectedDevice.num,
							context: context
						)
					{
						var dc = Config.DeviceConfig()
						dc.role = DeviceRoles(rawValue: deviceRole)!.protoEnumValue()
						dc.buttonGpio = UInt32(buttonGPIO)
						dc.buzzerGpio = UInt32(buzzerGPIO)
						dc.rebroadcastMode = RebroadcastModes(rawValue: rebroadcastMode)?.protoEnumValue() ?? RebroadcastModes.all.protoEnumValue()
						dc.nodeInfoBroadcastSecs = UInt32(nodeInfoBroadcastSecs)
						dc.doubleTapAsButtonPress = doubleTapAsButtonPress
						dc.isManaged = isManaged
						dc.tzdef = tzdef
						dc.ledHeartbeatDisabled = !ledHeartbeatEnabled

						let adminMessageId = nodeConfig.saveDeviceConfig(
							config: dc,
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
			}
			Spacer()
		}
		.navigationTitle("Device Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsDevice.id, parameters: nil)

			setDeviceValues()

			// Need to request a LoRaConfig from the remote node before allowing changes
			if let device = bleManager.getConnectedDevice(), node.deviceConfig == nil {
				Logger.mesh.info("empty device config")

				let connectedNode = coreDataTools.getNodeInfo(
					id: device.num,
					context: context
				)

				if let connectedNode, connectedNode.user != nil {
					nodeConfig.requestDeviceConfig(
						fromUser: connectedNode.user!,
						toUser: node.user!,
						adminIndex: connectedNode.myInfo?.adminIndex ?? 0
					)
				}
			}
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
	}

	func setDeviceValues() {
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
}
