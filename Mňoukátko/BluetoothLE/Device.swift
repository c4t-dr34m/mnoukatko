/*
Mňoukátko - a Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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
import CoreBluetooth
import Foundation

public struct Device: Identifiable, Equatable {
	public var peripheral: CBPeripheral

	public var id: String
	public var num: Int64
	public var name: String
	public var shortName: String
	public var longName: String
	public var firmwareVersion: String
	public var rssi: Int
	public var lastUpdate: Date

	public static func == (lhs: Device, rhs: Device) -> Bool {
		lhs.id == rhs.id
	}

	public func getSignalStrength() -> SignalStrength {
		if rssi > -65 {
			return SignalStrength.strong
		}
		else if rssi > -85 {
			return SignalStrength.normal
		}
		else {
			return SignalStrength.weak
		}
	}
}
