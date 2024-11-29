import CoreBluetooth
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog

final class BackgroundWatcher: DevicesDelegate {
	enum Tasks: CaseIterable {
		case deviceConnected
		case wantConfig
	}

	private(set) var tasksDone = [Tasks]()

	private let bleManager: BLEManager

	init(bleManager: BLEManager) {
		self.bleManager = bleManager
	}

	func startBackground() {
		tasksDone.removeAll()

		if bleManager.isConnected, bleManager.isSubscribed {
			Logger.app.debug("Background task started but node is still connected. No need to do anything")
			return
		}
		else {
			Logger.app.debug("Background task started")
		}

		bleManager.devicesDelegate = self
		bleManager.startScanning()

		// let's try to force connection without waiting for discovery
		if
			let preferredDevice = bleManager.devices.first(where: { device in
				device.peripheral.identifier.uuidString == UserDefaults.preferredPeripheralId
			})
		{
			bleManager.connectTo(peripheral: preferredDevice.peripheral)
		}
	}

	func stopBackground(runtime: TimeInterval) {
		let processInfo = ProcessInfo.processInfo
		if UserDefaults.powerSavingMode || processInfo.isLowPowerModeEnabled {
			bleManager.disconnectDevice()
			bleManager.automaticallyReconnect = false
		}

		scheduleSummaryNotification()

		Logger.app.warning(
			"Background task finished in \(Int(runtime))s; tasks done: \(self.tasksDone)"
		)

		Analytics.logEvent(
			AnalyticEvents.backgroundFinished.id,
			parameters: [
				"tasks_done": allTasksDone()
			]
		)
	}

	func allTasksDone() -> Bool {
		tasksDone.count == Tasks.allCases.count
	}

	func onChange(devices: [Device]) {
		Logger.app.debug("Background: devices \(devices)")

		let device = devices.last(where: { device in
			device.peripheral.identifier.uuidString == UserDefaults.preferredPeripheralId
		})

		guard let device else {
			return
		}

		bleManager.stopScanning()

		if device.peripheral.state == .connected  {
			onDeviceConnected(name: device.peripheral.name)
		}
		else {
			bleManager.connectTo(peripheral: device.peripheral)
		}
	}

	func onDeviceConnected(name: String?) {
		guard !tasksDone.contains(.deviceConnected) else {
			return
		}

		Analytics.logEvent(
			AnalyticEvents.backgroundDeviceConnected.id,
			parameters: [
				"name": name ?? "N/A"
			]
		)

		tasksDone.append(.deviceConnected)
	}

	func onWantConfigFinished() {
		guard !tasksDone.contains(.wantConfig) else {
			return
		}

		Analytics.logEvent(AnalyticEvents.backgroundWantConfig.id, parameters: nil)

		tasksDone.append(.wantConfig)
	}

	private func scheduleSummaryNotification() {
		guard UserDefaults.bcgNotification else {
			return
		}

		// swiftlint:disable:next force_unwrapping
		let lastFifteenMinutes = Calendar.current.date(byAdding: .minute, value: -15, to: .now)! as NSDate
		let request = NodeInfoEntity.fetchRequest()
		request.predicate = NSPredicate(format: "lastHeard >= %@", lastFifteenMinutes)

		let nodeCount: Int
		let nodeName: String?
		let nodeInfo: String

		if let nodes = try? bleManager.context.fetch(request) {
			if
				let connectedNode = nodes.first(where: { node in
					node.num == UserDefaults.preferredPeripheralNum
				})
			{
				nodeCount = nodes.count - 1
				nodeName = connectedNode.user?.longName ?? bleManager.getConnectedDevice()?.longName
			}
			else {
				nodeCount = nodes.count
				nodeName = bleManager.getConnectedDevice()?.longName
			}
		}
		else {
			nodeCount = 0
			nodeName = bleManager.getConnectedDevice()?.longName
		}

		if nodeCount == 0 {
			nodeInfo = "Your node currently doesn't see any node."
		}
		else if nodeCount == 1 {
			nodeInfo = "Your node currently sees one other node."
		}
		else {
			nodeInfo = "Your node currently sees \(nodeCount) other nodes."
		}

		let manager = LocalNotificationManager()
		manager.queue(
			notification: Notification(
				id: "notification.id.bcg_update",
				title: "Node Update",
				subtitle: nodeName,
				body: nodeInfo,
				path: URL(string: "meow://nodes")
			),
			silent: true,
			removeExisting: true
		)
	}
}
