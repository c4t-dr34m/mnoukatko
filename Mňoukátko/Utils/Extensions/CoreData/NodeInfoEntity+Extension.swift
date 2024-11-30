/*
Mňoukátko - the Meshtastic® client

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
import Foundation
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

	var hasDeviceMetrics: Bool {
		telemetries?.first(where: { telemetry in
			(telemetry as AnyObject).metricsType == 0
		}) != nil
	}

	var hasEnvironmentMetrics: Bool {
		telemetries?.first(where: { telemetry in
			(telemetry as AnyObject).metricsType == 1
		}) != nil
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
		if lastHeard?.compare(fifteenMinutesAgo) == .orderedDescending {
			 return true
		}

		return false
	}
}

public func createNodeInfo(num: Int64, context: NSManagedObjectContext) -> NodeInfoEntity {
	let userId = String(format: "%2X", num)
	let last4 = String(userId.suffix(4))

	let newUser = UserEntity(context: context)
	newUser.num = Int64(num)
	newUser.userId = "!\(userId)"
	newUser.longName = "Meshtastic \(last4)"
	newUser.shortName = last4
	newUser.hwModel = "UNSET"

	let newNode = NodeInfoEntity(context: context)
	newNode.id = Int64(num)
	newNode.num = Int64(num)
	newNode.user = newUser

	return newNode
}
