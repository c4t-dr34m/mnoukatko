/*
The Meow - the Meshtastic® client

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
