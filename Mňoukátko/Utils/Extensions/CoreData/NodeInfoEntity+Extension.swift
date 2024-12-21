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
import CoreData
import CoreLocation
import Foundation
import OSLog
import SwiftUI

extension NodeInfoEntity {
	var color: Color {
		Color(
			UIColor(hex: UInt32(num))
		)
	}

	var latestEnvironmentMetrics: TelemetryEntity? {
		telemetries?.filtered(
			using: NSPredicate(format: "metricsType == 1")
		).lastObject as? TelemetryEntity
	}

	var hasPositions: Bool {
		positions?.count ?? 0 > 0
	}

	var latestPosition: PositionEntity? {
		positions?.lastObject as? PositionEntity
	}

	var lastHeardAt: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: lastHeardAtLatitude, longitude: lastHeardAtLongitude)
	}

	var hasDeviceMetrics: Bool {
		telemetries?.contains(where: { telemetry in
			(telemetry as AnyObject).metricsType == 0
		}) == true
	}

	var hasEnvironmentMetrics: Bool {
		telemetries?.contains(where: { telemetry in
			(telemetry as AnyObject).metricsType == 1
		}) == true
	}

	var hasDetectionSensorMetrics: Bool {
		user?.sensorMessageList?.count ?? 0 > 0
	}

	var hasTraceRoutes: Bool {
		traceRoutes?.count ?? 0 > 0
	}

	var hasPax: Bool {
		pax?.count ?? 0 > 0
	}

	var isStoreForwardRouter: Bool {
		storeForwardConfig?.isRouter ?? false
	}

	var isOnline: Bool {
		// swiftlint:disable:next force_unwrapping
		let fifteenMinutesAgo = Calendar.current.date(byAdding: .minute, value: -15, to: .now)!

		if let lastHeard, lastHeard.compare(fifteenMinutesAgo) == .orderedDescending {
			return true
		}

		return false
	}

	static func create(for num: Int64, with context: NSManagedObjectContext) -> NodeInfoEntity {
		let userId = String(format: "%2X", num)
		let last4 = String(userId.suffix(4))

		let newUser = UserEntity(context: context)
		newUser.num = Int64(num)
		newUser.userId = "!\(userId)"
		newUser.longName = "#\(last4)"
		newUser.shortName = last4
		newUser.hwModel = "UNSET"

		let newNode = NodeInfoEntity(context: context)
		newNode.id = Int64(num)
		newNode.num = Int64(num)
		newNode.user = newUser

		return newNode
	}

	func setLastHeard(at timestamp: UInt32, by device: Device?) {
		guard timestamp > 0 else {
			return
		}

		let timeInterval = TimeInterval(Int64(timestamp))
		let date = Date(timeIntervalSince1970: timeInterval)

		// swiftlint:disable:next force_unwrapping
		if firstHeard == nil || date < firstHeard! {
			firstHeard = date
		}

		// swiftlint:disable:next force_unwrapping
		if lastHeard == nil || date > lastHeard! {
			lastHeard = date
			lastHeardBy = device?.nodeInfo

			setLastHeardAt(when: date, connectedDevice: device)
		}
	}

	private func setLastHeardAt(when date: Date, connectedDevice device: Device?) {
		if
			let position = getClosestPosition(to: date, connectedDevice: device),
			position.latitudeI != 0, position.longitudeI != 0
		{
			lastHeardAtLatitude = position.latitude
			lastHeardAtLongitude = position.longitude

			if let precision = PositionPrecision(rawValue: Int(position.precisionBits)) {
				lastHeardAtPrecision = precision.precisionMeters
			}

			Logger.location.debug("Last heard at updated for \(self.user?.longName ?? "#\(self.num)") (node)")
			Logger.location.debug(
				"↑ \(self.lastHeardAtLatitude),\(self.lastHeardAtLongitude) from \(position.time?.relative() ?? "N/A")"
			)
		}
		else if let location = LocationManager.shared.getLocation() {
			lastHeardAtLatitude = location.coordinate.latitude
			lastHeardAtLongitude = location.coordinate.longitude
			lastHeardAtPrecision = location.horizontalAccuracy

			Logger.location.debug("Last heard at updated for \(self.user?.longName ?? "#\(self.num)") (device)")
		}
	}

	private func getClosestPosition(to date: Date, connectedDevice device: Device?) -> PositionEntity? {
		guard
			let positions = device?.nodeInfo?.positions?.array as? [PositionEntity],
			positions.count > 0
		else {
			return nil
		}

		var delta = Double.greatestFiniteMagnitude
		var closest: PositionEntity?

		for position in positions {
			guard let time = position.time else {
				continue
			}

			let currentDelta = abs(time.distance(to: date))
			if currentDelta < delta {
				delta = currentDelta
				closest = position
			}
		}

		return closest
	}
}
