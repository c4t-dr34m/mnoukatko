import CoreData
import Foundation

public final class CurrentDevice: ObservableObject, Equatable {
	@Published
	private(set) var device: Device?

	private let context: NSManagedObjectContext

	init(context: NSManagedObjectContext) {
		self.context = context
	}

	public static func == (lhs: CurrentDevice, rhs: CurrentDevice) -> Bool {
		lhs.device?.id == rhs.device?.id
	}

	public func set(device: Device) {
		self.device = device
	}

	@discardableResult
	public func update(with newDevice: Device) -> Bool {
		guard let device, device.peripheral.state == .connected else {
			return false
		}

		self.device = newDevice

		return true
	}

	public func clear() {
		self.device?.peripheral.delegate = nil
		self.device = nil
	}

	public func getConnectedDevice() -> Device? {
		guard let device, device.peripheral.state == .connected else {
			return nil
		}

		return device
	}
}
