import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct DisplayConfig: View {
	private let coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack

	var node: NodeInfoEntity

	@State var hasChanges = false
	@State var screenOnSeconds = 0
	@State var screenCarouselInterval = 0
	@State var gpsFormat = 0
	@State var compassNorthTop = false
	@State var wakeOnTapOrMotion = false
	@State var flipScreen = false
	@State var oledType = 0
	@State var displayMode = 0
	@State var units = 0

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
		}
		.disabled(connectedDevice.device == nil || node.displayConfig == nil)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsDisplay.id, parameters: nil)
		}

		SaveConfigButton(node: node, hasChanges: $hasChanges) {
			if
				let device = connectedDevice.device,
				let connectedNode = coreDataTools.getNodeInfo(
					id: device.num,
					context: context
				)
			{
				var dc = Config.DisplayConfig()
				dc.gpsFormat = GPSFormats(rawValue: gpsFormat)!.protoEnumValue()
				dc.screenOnSecs = UInt32(screenOnSeconds)
				dc.autoScreenCarouselSecs = UInt32(screenCarouselInterval)
				dc.compassNorthTop = compassNorthTop
				dc.wakeOnTapOrMotion = wakeOnTapOrMotion
				dc.flipScreen = flipScreen
				dc.oled = OLEDTypes(rawValue: oledType)!.protoEnumValue()
				dc.displaymode = DisplayModes(rawValue: displayMode)!.protoEnumValue()
				dc.units = Units(rawValue: units)!.protoEnumValue()

				let adminMessageId = nodeConfig.saveDisplayConfig(
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

		.navigationTitle("Display Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			setDisplayValues()

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

	private func setDisplayValues() {
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

		self.hasChanges = false
	}
}
