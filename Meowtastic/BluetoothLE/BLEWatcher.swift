import CoreBluetooth
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog

final class BLEWatcher: DevicesDelegate {
	private enum Tasks: CaseIterable {
		case deviceConnected
		case wantConfig
	}

	private let bleManager: BLEManager

	private var tasksDone = [Tasks]()

	init(bleManager: BLEManager) {
		self.bleManager = bleManager
	}

	func start() {
		tasksDone.removeAll()

		bleManager.devicesDelegate = self
		bleManager.startScanning()
	}

	func allTasksDone() -> Bool {
		tasksDone.count == Tasks.allCases.count
	}

	func onChange(devices: [Device]) {
		Logger.app.debug("Background: devices \(devices)")

		let device = devices.first(where: { device in
			device.peripheral.state != CBPeripheralState.connected
			&& device.peripheral.state != CBPeripheralState.connecting
			&& device.peripheral.identifier.uuidString == UserDefaults.preferredPeripheralId
		})

		guard let device else {
			return
		}

		bleManager.stopScanning()
		bleManager.connectTo(peripheral: device.peripheral)
	}

	func onDeviceConnected(name: String?) {
		Analytics.logEvent(
			AnalyticEvents.backgroundDeviceConnected.id,
			parameters: [
				"name": name ?? "N/A"
			]
		)

		tasksDone.append(.deviceConnected)
	}

	func onWantConfigFinished() {
		Analytics.logEvent(AnalyticEvents.backgroundWantConfig.id, parameters: nil)

		// TODO
		let manager = LocalNotificationManager()
		manager.notifications = [
			Notification(
				title: "Update",
				subtitle: "Background update finished",
				content: "Yay, new data!",
				target: "nodes"
			)
		]
		manager.schedule()

		tasksDone.append(.wantConfig)
	}
}
