/*
Meow - the Meshtastic® client

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
				Picker("Display mode", selection: $displayMode ) {
					ForEach(DisplayModes.allCases) { dm in
						Text(dm.description)
					}
				}

				Toggle(isOn: $compassNorthTop) {
					Text("Always point north")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $wakeOnTapOrMotion) {
					Text("Wake screen on tap or motion")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $flipScreen) {
					Text("Flip screen")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				VStack(alignment: .leading) {
					Picker("OLED type", selection: $oledType ) {
						ForEach(OLEDTypes.allCases) { ot in
							Text(ot.description)
						}
					}
				}
			}
			.headerProminence(.increased)

			Section(header: Text("Timing & Format")) {
				Picker("Screen on", selection: $screenOnSeconds ) {
					ForEach(ScreenOnIntervals.allCases) { soi in
						Text(soi.description)
					}
				}

				Picker("Carousel interval", selection: $screenCarouselInterval ) {
					ForEach(ScreenCarouselIntervals.allCases) { sci in
						Text(sci.description)
					}
				}

				Picker("GPS format", selection: $gpsFormat ) {
					ForEach(GPSFormats.allCases) { lu in
						Text(lu.description)
					}
				}

				Picker("Units", selection: $units ) {
					ForEach(Units.allCases) { un in
						Text(un.description)
					}
				}
			}
			.headerProminence(.increased)
		}
		.disabled(connectedDevice.device == nil || node.displayConfig == nil)
		.navigationTitle("Display Config")
		.navigationBarItems(
			trailing: SaveButton(changes: $hasChanges) {
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
