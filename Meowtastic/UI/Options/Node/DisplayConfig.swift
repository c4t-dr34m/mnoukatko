import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct DisplayConfig: OptionsScreen {
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
	private var hasChanges = false
	@State
	private var screenOnSeconds = 0
	@State
	private var screenCarouselInterval = 0
	@State
	private var gpsFormat = 0
	@State
	private var compassNorthTop = false
	@State
	private var wakeOnTapOrMotion = false
	@State
	private var flipScreen = false
	@State
	private var oledType = 0
	@State
	private var displayMode = 0
	@State
	private var units = 0

	var body: some View {
		Form {
			Section(header: Text("Device Screen")) {
				VStack(alignment: .leading) {
					Picker("Display Mode", selection: $displayMode ) {
						ForEach(DisplayModes.allCases) { dm in
							Text(dm.description)
						}
					}

					Text("Override automatic OLED screen detection.")
						.foregroundColor(.gray)
						.font(.callout)
				}
				.pickerStyle(DefaultPickerStyle())
				Toggle(isOn: $compassNorthTop) {
					Label("Always point north", systemImage: "location.north.circle")
					Text("The compass heading on the screen outside of the circle will always point north.")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $wakeOnTapOrMotion) {
					Label("Wake Screen on tap or motion", systemImage: "gyroscope")
					Text("Requires that there be an accelerometer on your device.")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $flipScreen) {
					Label("Flip Screen", systemImage: "pip.swap")
					Text("Flip screen vertically")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				VStack(alignment: .leading) {
					Picker("OLED Type", selection: $oledType ) {
						ForEach(OLEDTypes.allCases) { ot in
							Text(ot.description)
						}
					}
					Text("Override automatic OLED screen detection.")
						.foregroundColor(.gray)
						.font(.callout)
				}
				.pickerStyle(DefaultPickerStyle())
			}
			.headerProminence(.increased)

			Section(header: Text("Timing & Format")) {
				VStack(alignment: .leading) {
					Picker("Screen on for", selection: $screenOnSeconds ) {
						ForEach(ScreenOnIntervals.allCases) { soi in
							Text(soi.description)
						}
					}
					Text("How long the screen remains on after the user button is pressed or messages are received.")
						.foregroundColor(.gray)
						.font(.callout)
				}
				.pickerStyle(DefaultPickerStyle())

				VStack(alignment: .leading) {
					Picker("Carousel Interval", selection: $screenCarouselInterval ) {
						ForEach(ScreenCarouselIntervals.allCases) { sci in
							Text(sci.description)
						}
					}

					Text("Automatically toggles to the next page on the screen like a carousel, based the specified interval.")
						.foregroundColor(.gray)
						.font(.callout)
				}
				.pickerStyle(DefaultPickerStyle())

				VStack(alignment: .leading) {
					Picker("GPS Format", selection: $gpsFormat ) {
						ForEach(GPSFormats.allCases) { lu in
							Text(lu.description)
						}
					}

					Text("The format used to display GPS coordinates on the device screen.")
						.foregroundColor(.gray)
						.font(.callout)
				}
				.pickerStyle(DefaultPickerStyle())

				VStack(alignment: .leading) {
					Picker("Display Units", selection: $units ) {
						ForEach(Units.allCases) { un in
							Text(un.description)
						}
					}

					Text("Units displayed on the device screen")
						.foregroundColor(.gray)
						.font(.callout)
				}
				.pickerStyle(DefaultPickerStyle())
			}
			.headerProminence(.increased)
		}
		.disabled(connectedDevice.device == nil || node.displayConfig == nil)
		.navigationTitle("Display Config")
		.navigationBarItems(
			trailing: SaveButton(node, changes: $hasChanges) {
				save()
			}
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsDisplay.id, parameters: nil)
			setInitialValues()

			// Need to request a LoRaConfig from the remote node before allowing changes
			if
				let device = connectedDevice.device,
				node.displayConfig == nil,
				let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context)
			{
				nodeConfig.requestDisplayConfig(
					fromUser: connectedNode.user!,
					toUser: node.user!,
					adminIndex: connectedNode.myInfo?.adminIndex ?? 0
				)
			}
		}
		.onChange(of: screenOnSeconds) {
			hasChanges = true
		}
		.onChange(of: screenCarouselInterval) {
			hasChanges = true
		}
		.onChange(of: compassNorthTop) {
			hasChanges = true
		}
		.onChange(of: wakeOnTapOrMotion) {
			hasChanges = true
		}
		.onChange(of: gpsFormat) {
			hasChanges = true
		}
		.onChange(of: flipScreen) {
			hasChanges = true
		}
		.onChange(of: oledType) {
			hasChanges = true
		}
		.onChange(of: displayMode) {
			hasChanges = true
		}
		.onChange(of: units) {
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
			node.displayConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestDisplayConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.displayConfig {
			gpsFormat = Int(config.gpsFormat)
			compassNorthTop = config.compassNorthTop
			wakeOnTapOrMotion = config.wakeOnTapOrMotion
			flipScreen = config.flipScreen
			screenOnSeconds = Int(config.screenOnSeconds)
			screenCarouselInterval = Int(config.screenCarouselInterval)
			oledType = Int(config.oledType)
			displayMode = Int(config.displayMode)
			units = Int(config.units)
		}
		else {
			compassNorthTop = false
			wakeOnTapOrMotion = false
			flipScreen = false
			gpsFormat = 0
			screenOnSeconds = 0
			screenCarouselInterval = 0
			oledType = 0
			displayMode = 0
			units = 0
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
		var config = Config.DisplayConfig()
		config.gpsFormat = GPSFormats(rawValue: gpsFormat)!.protoEnumValue()
		config.screenOnSecs = UInt32(screenOnSeconds)
		config.autoScreenCarouselSecs = UInt32(screenCarouselInterval)
		config.compassNorthTop = compassNorthTop
		config.wakeOnTapOrMotion = wakeOnTapOrMotion
		config.flipScreen = flipScreen
		config.oled = OLEDTypes(rawValue: oledType)!.protoEnumValue()
		config.displaymode = DisplayModes(rawValue: displayMode)!.protoEnumValue()
		config.units = Units(rawValue: units)!.protoEnumValue()
		// swiftlint:enable force_unwrapping

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveDisplayConfig(
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
