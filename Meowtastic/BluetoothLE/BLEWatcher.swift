import CoreBluetooth
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog

final class BLEWatcher: DevicesDelegate {
	enum Tasks: CaseIterable {
		case deviceConnected
		case wantConfig
	}

	private(set) var tasksDone = [Tasks]()

	private let bleManager: BLEManager

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
			device.peripheral.identifier.uuidString == UserDefaults.preferredPeripheralId
		})

		guard let device else {
			return
		}

		bleManager.stopScanning()

		if device.peripheral.state == .connected  {
			onDeviceConnected(name: device.peripheral.name)
		}
		else if device.peripheral.state != .connecting {
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
}
