import CoreLocation
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct PositionConfig: OptionsScreen {
	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	private let locationManager = CLLocationManager()

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
	private var supportedVersion = true
	@State
	private var showingSetFixedAlert = false
	@State
	private var hasChanges = false
	@State
	private var hasFlagChanges = false
	@State
	private var smartPositionEnabled = true
	@State
	private var deviceGpsEnabled = true
	@State
	private var gpsMode = 0
	@State
	private var rxGpio = 0
	@State
	private var txGpio = 0
	@State
	private var gpsEnGpio = 0
	@State
	private var fixedPosition = false
	@State
	private var gpsUpdateInterval = 0
	@State
	private var positionBroadcastSeconds = 0
	@State
	private var broadcastSmartMinimumDistance = 0
	@State
	private var broadcastSmartMinimumIntervalSecs = 0
	@State
	private var positionFlags = 811
	@State
	private var includeAltitude = false
	@State
	private var includeAltitudeMsl = false
	@State
	private var includeGeoidalSeparation = false
	@State
	private var includeDop = false
	@State
	private var includeHvdop = false
	@State
	private var includeSatsinview = false
	@State
	private var includeSeqNo = false
	@State
	private var includeTimestamp = false
	@State
	private var includeSpeed = false
	@State
	private var includeHeading = false
	@State
	private var minimumVersion = "2.3.3"

	@ViewBuilder
	var body: some View {
		VStack {
			Form {
				positionPacketSection
				deviceGPSSection
				positionFlagsSection
				advancedPositionFlagsSection

				if gpsMode == 1 {
					advancedDeviceGPSSection
				}
			}
			.disabled(connectedDevice.device == nil || node.positionConfig == nil)
			.navigationTitle("Position Config")
			.navigationBarItems(
				trailing: SaveButton(node, changes: $hasChanges) {
					save()
				}
			)
			.onAppear {
				Analytics.logEvent(AnalyticEvents.optionsPosition.id, parameters: nil)

				supportedVersion = bleManager.connectedVersion == "0.0.0"
				|| minimumVersion.compare(bleManager.connectedVersion, options: .numeric) == .orderedAscending
				|| minimumVersion.compare(bleManager.connectedVersion, options: .numeric) == .orderedSame

				setInitialValues()
			}
			.onChange(of: fixedPosition) {
				guard supportedVersion, let positionConfig = node.positionConfig else {
					return
				}

				if !positionConfig.fixedPosition, fixedPosition {
					showingSetFixedAlert = true
				}
				else if positionConfig.fixedPosition, !fixedPosition {
					showingSetFixedAlert = true
				}
			}
			.onChange(of: gpsMode) {
				handleChanges()
			}
			.onChange(of: rxGpio) {
				handleChanges()
			}
			.onChange(of: txGpio) {
				handleChanges()
			}
			.onChange(of: gpsEnGpio) {
				handleChanges()
			}
			.onChange(of: smartPositionEnabled) {
				handleChanges()
			}
			.onChange(of: positionBroadcastSeconds) {
				handleChanges()
			}
			.onChange(of: broadcastSmartMinimumIntervalSecs) {
				handleChanges()
			}
			.onChange(of: broadcastSmartMinimumDistance) {
				handleChanges()
			}
			.onChange(of: gpsUpdateInterval) {
				handleChanges()
			}
			.onChange(of: positionFlags) {
				handleChanges()
			}
			.alert(setFixedAlertTitle, isPresented: $showingSetFixedAlert) {
				Button("Cancel", role: .cancel) {
					fixedPosition.toggle()
				}

				if node.positionConfig?.fixedPosition ?? false {
					Button("Remove", role: .destructive) {
						removeFixedPosition()
					}
				}
				else {
					Button("Set") {
						setFixedPosition()
					}
				}
			} message: {
				Text(node.positionConfig?.fixedPosition ?? false ? "This will disable fixed position and remove the currently set position." : "This will send a current position from your phone and enable fixed position.")
			}
		}
	}

	@ViewBuilder
	var positionPacketSection: some View {
		Section(header: Text("Position Packet")) {
			VStack(alignment: .leading) {
				Picker("Broadcast Interval", selection: $positionBroadcastSeconds) {
					ForEach(UpdateIntervals.allCases) { at in
						if at.rawValue >= 300 {
							Text(at.description)
						}
					}
				}
				.pickerStyle(DefaultPickerStyle())
				Text("The maximum interval that can elapse without a node broadcasting a position")
					.foregroundColor(.gray)
					.font(.callout)
			}

			Toggle(isOn: $smartPositionEnabled) {
				Label("Smart Position", systemImage: "brain")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			if smartPositionEnabled {
				VStack(alignment: .leading) {
					Picker("Minimum Interval", selection: $broadcastSmartMinimumIntervalSecs) {
						ForEach(UpdateIntervals.allCases) { at in
							Text(at.description)
						}
					}
					.pickerStyle(DefaultPickerStyle())

					Text("The fastest that position updates will be sent if the minimum distance has been satisfied")
						.foregroundColor(.gray)
						.font(.callout)
				}

				VStack(alignment: .leading) {
					let options = [0, 10, 25, 50, 75, 100, 125, 150]
					Picker("Minimum Distance", selection: $broadcastSmartMinimumDistance) {
						ForEach(options, id: \.self) {
							if $0 == 0 {
								Text("Unset")
							}
							else {
								Text("\($0)")
									.tag($0)
							}
						}
					}
					.pickerStyle(DefaultPickerStyle())

					Text("The minimum distance change in meters to be considered for a smart position broadcast.")
						.foregroundColor(.gray)
						.font(.callout)
				}
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	var deviceGPSSection: some View {
		Section(header: Text("Device GPS")) {
			Picker("", selection: $gpsMode) {
				ForEach(GPSMode.allCases, id: \.self) { at in
					Text(at.description)
						.tag(at.id)
				}
			}
			.pickerStyle(SegmentedPickerStyle())
			.padding(.top, 5)
			.padding(.bottom, 5)
			.disabled(fixedPosition && !(gpsMode == 1))

			if gpsMode == 1 {
				Text("Positions will be provided by your device GPS, if you select disabled or not present you can set a fixed position.")
					.foregroundColor(.gray)
					.font(.callout)

				VStack(alignment: .leading) {
					Picker("Update Interval", selection: $gpsUpdateInterval) {
						ForEach(GPSUpdateIntervals.allCases) { ui in
							Text(ui.description)
						}
					}
					Text("How often should we try to get a GPS position.")
						.foregroundColor(.gray)
						.font(.callout)
				}
			}
			if (gpsMode != 1 && node.num == bleManager.getConnectedDevice()?.num ?? -1) || fixedPosition {
				VStack(alignment: .leading) {
					Toggle(isOn: $fixedPosition) {
						Label("Fixed Position", systemImage: "location.square.fill")

						if !(node.positionConfig?.fixedPosition ?? false) {
							Text("Your current location will be set as the fixed position and broadcast over the mesh on the position interval.")
						}
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	var positionFlagsSection: some View {
		Section(header: Text("Position Flags")) {
			Text("Optional fields to include when assembling position messages. the more fields are included, the larger the message will be - leading to longer airtime and a higher risk of packet loss")
				.foregroundColor(.gray)
				.font(.callout)

			Toggle(isOn: $includeAltitude) {
				Label("Altitude", systemImage: "arrow.up")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Toggle(isOn: $includeSatsinview) {
				Label("Number of satellites", systemImage: "skew")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Toggle(isOn: $includeSeqNo) { // 64
				Label("Sequence number", systemImage: "number")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Toggle(isOn: $includeTimestamp) { // 128
				Label("timestamp", systemImage: "clock")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Toggle(isOn: $includeHeading) { // 128
				Label("Vehicle heading", systemImage: "location.circle")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			Toggle(isOn: $includeSpeed) { // 128
				Label("Vehicle speed", systemImage: "speedometer")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	var advancedPositionFlagsSection: some View {
		Section(header: Text("Advanced Position Flags")) {
			if includeAltitude {
				Toggle(isOn: $includeAltitudeMsl) {
					Label("Altitude is Mean Sea Level", systemImage: "arrow.up.to.line.compact")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				Toggle(isOn: $includeGeoidalSeparation) {
					Label("Altitude Geoidal Separation", systemImage: "globe.americas")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}

			Toggle(isOn: $includeDop) {
				Text("Dilution of precision (DOP) PDOP used by default")
			}
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))

			if includeDop {
				Toggle(isOn: $includeHvdop) {
					Text("If DOP is set, use HDOP / VDOP values instead of PDOP")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
		}
		.headerProminence(.increased)
	}

	@ViewBuilder
	var advancedDeviceGPSSection: some View {
		Section(header: Text("Advanced Device GPS")) {
			Picker("GPS Receive GPIO", selection: $rxGpio) {
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

			Picker("GPS Transmit GPIO", selection: $txGpio) {
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

			Picker("GPS EN GPIO", selection: $gpsEnGpio) {
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

			Text("(Re)define PIN_GPS_EN for your board.")
				.font(.caption)
		}
		.headerProminence(.increased)
	}

	var setFixedAlertTitle: String {
		if node.positionConfig?.fixedPosition == true {
			return "Remove Fixed Position"
		}
		else {
			return "Set Fixed Position"
		}
	}

	func handleChanges() {
		guard let positionConfig = node.positionConfig else {
			return
		}

		let hasLocation = [.authorizedWhenInUse, .authorizedAlways]
			.contains(locationManager.authorizationStatus)
		if !hasLocation, gpsMode == GPSMode.enabled.rawValue || fixedPosition == true {
			locationManager.requestAlwaysAuthorization()
		}

		let pf = PositionFlags(rawValue: self.positionFlags)
		hasChanges = positionConfig.deviceGpsEnabled != deviceGpsEnabled ||
		positionConfig.gpsMode != gpsMode ||
		positionConfig.rxGpio != rxGpio ||
		positionConfig.txGpio != txGpio ||
		positionConfig.gpsEnGpio != gpsEnGpio ||
		positionConfig.smartPositionEnabled != smartPositionEnabled ||
		positionConfig.positionBroadcastSeconds != positionBroadcastSeconds ||
		positionConfig.broadcastSmartMinimumIntervalSecs != broadcastSmartMinimumIntervalSecs ||
		positionConfig.broadcastSmartMinimumDistance != broadcastSmartMinimumDistance ||
		positionConfig.gpsUpdateInterval != gpsUpdateInterval ||
		pf.contains(.Altitude) ||
		pf.contains(.AltitudeMsl) ||
		pf.contains(.Satsinview) ||
		pf.contains(.SeqNo) ||
		pf.contains(.Timestamp) ||
		pf.contains(.Speed) ||
		pf.contains(.Heading) ||
		pf.contains(.GeoidalSeparation) ||
		pf.contains(.Dop) ||
		pf.contains(.Hvdop)
	}

	func setPositionValues() {
		smartPositionEnabled = node.positionConfig?.smartPositionEnabled ?? true
		deviceGpsEnabled = node.positionConfig?.deviceGpsEnabled ?? false
		gpsMode = Int(node.positionConfig?.gpsMode ?? 0)
		if node.positionConfig?.deviceGpsEnabled ?? false && gpsMode != 1 {
			gpsMode = 1
		}
		rxGpio = Int(node.positionConfig?.rxGpio ?? 0)
		txGpio = Int(node.positionConfig?.txGpio ?? 0)
		gpsEnGpio = Int(node.positionConfig?.gpsEnGpio ?? 0)
		fixedPosition = node.positionConfig?.fixedPosition ?? false
		gpsUpdateInterval = Int(node.positionConfig?.gpsUpdateInterval ?? 30)
		positionBroadcastSeconds = Int(node.positionConfig?.positionBroadcastSeconds ?? 900)
		broadcastSmartMinimumIntervalSecs = Int(node.positionConfig?.broadcastSmartMinimumIntervalSecs ?? 30)
		broadcastSmartMinimumDistance = Int(node.positionConfig?.broadcastSmartMinimumDistance ?? 50)
		positionFlags = Int(node.positionConfig?.positionFlags ?? 3)

		let pf = PositionFlags(rawValue: self.positionFlags)
		self.includeAltitude = pf.contains(.Altitude)
		self.includeAltitudeMsl = pf.contains(.AltitudeMsl)
		self.includeGeoidalSeparation = pf.contains(.GeoidalSeparation)
		self.includeDop = pf.contains(.Dop)
		self.includeHvdop = pf.contains(.Hvdop)
		self.includeSatsinview = pf.contains(.Satsinview)
		self.includeSeqNo = pf.contains(.SeqNo)
		self.includeTimestamp = pf.contains(.Timestamp)
		self.includeSpeed = pf.contains(.Speed)
		self.includeHeading = pf.contains(.Heading)

		self.hasChanges = false
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.positionConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestPositionConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.positionConfig {
			smartPositionEnabled = config.smartPositionEnabled
			deviceGpsEnabled = config.deviceGpsEnabled
			fixedPosition = config.fixedPosition
			rxGpio = Int(config.rxGpio)
			txGpio = Int(config.txGpio)
			gpsEnGpio = Int(config.gpsEnGpio)
			gpsUpdateInterval = Int(config.gpsUpdateInterval)
			positionBroadcastSeconds = Int(config.positionBroadcastSeconds)
			broadcastSmartMinimumIntervalSecs = Int(config.broadcastSmartMinimumIntervalSecs)
			broadcastSmartMinimumDistance = Int(config.broadcastSmartMinimumDistance)
			positionFlags = Int(config.positionFlags)

			gpsMode = Int(config.gpsMode)
			if config.deviceGpsEnabled, gpsMode != 1 {
				gpsMode = 1
			}
		}
		else {
			smartPositionEnabled = true
			deviceGpsEnabled = false
			fixedPosition = false
			rxGpio = 0
			txGpio = 0
			gpsEnGpio = 0
			gpsUpdateInterval = 30
			positionBroadcastSeconds = 900
			broadcastSmartMinimumIntervalSecs = 30
			broadcastSmartMinimumDistance = 50
			positionFlags = 3

			gpsMode = 0
		}

		let flags = PositionFlags(rawValue: self.positionFlags)
		includeAltitude = flags.contains(.Altitude)
		includeAltitudeMsl = flags.contains(.AltitudeMsl)
		includeGeoidalSeparation = flags.contains(.GeoidalSeparation)
		includeDop = flags.contains(.Dop)
		includeHvdop = flags.contains(.Hvdop)
		includeSatsinview = flags.contains(.Satsinview)
		includeSeqNo = flags.contains(.SeqNo)
		includeTimestamp = flags.contains(.Timestamp)
		includeSpeed = flags.contains(.Speed)
		includeHeading = flags.contains(.Heading)

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

		var flags: PositionFlags = []
		if includeAltitude {
			flags.insert(.Altitude)
		}
		if includeAltitudeMsl {
			flags.insert(.AltitudeMsl)
		}
		if includeGeoidalSeparation {
			flags.insert(.GeoidalSeparation)
		}
		if includeDop {
			flags.insert(.Dop)
		}
		if includeHvdop {
			flags.insert(.Hvdop)
		}
		if includeSatsinview {
			flags.insert(.Satsinview)
		}
		if includeSeqNo {
			flags.insert(.SeqNo)
		}
		if includeTimestamp {
			flags.insert(.Timestamp)
		}
		if includeSpeed {
			flags.insert(.Speed)
		}
		if includeHeading {
			flags.insert(.Heading)
		}

		var config = Config.PositionConfig()
		config.positionBroadcastSmartEnabled = smartPositionEnabled
		config.gpsEnabled = gpsMode == 1
		config.gpsMode = Config.PositionConfig.GpsMode(
			rawValue: gpsMode
		) ?? Config.PositionConfig.GpsMode.notPresent
		config.fixedPosition = fixedPosition
		config.gpsUpdateInterval = UInt32(gpsUpdateInterval)
		config.positionBroadcastSecs = UInt32(positionBroadcastSeconds)
		config.broadcastSmartMinimumIntervalSecs = UInt32(broadcastSmartMinimumIntervalSecs)
		config.broadcastSmartMinimumDistance = UInt32(broadcastSmartMinimumDistance)
		config.rxGpio = UInt32(rxGpio)
		config.txGpio = UInt32(txGpio)
		config.gpsEnGpio = UInt32(gpsEnGpio)
		config.positionFlags = UInt32(flags.rawValue)

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.savePositionConfig(
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

	private func setFixedPosition() {
		guard let nodeNum = bleManager.getConnectedDevice()?.num, nodeNum > 0 else {
			return
		}

		if !nodeConfig.setFixedPosition(fromUser: node.user!, adminIndex: 0) {
			Logger.mesh.error("Set Position Failed")
		}

		node.positionConfig?.fixedPosition = true

		do {
			try context.save()
		}
		catch {
			context.rollback()
		}
	}

	private func removeFixedPosition() {
		guard let nodeNum = bleManager.getConnectedDevice()?.num, nodeNum > 0 else {
			return
		}

		if !nodeConfig.removeFixedPosition(fromUser: node.user!, adminIndex: 0) {
			Logger.mesh.error("Remove Fixed Position Failed")
		}

		let mutablePositions = node.positions?.mutableCopy() as? NSMutableOrderedSet
		mutablePositions?.removeAllObjects()

		node.positions = mutablePositions
		node.positionConfig?.fixedPosition = false

		do {
			try context.save()
		}
		catch {
			context.rollback()
		}
	}
}
