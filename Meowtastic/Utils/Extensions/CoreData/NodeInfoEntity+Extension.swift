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
		return telemetries?.filter { telemetry in
			(telemetry as AnyObject).metricsType == 0
		}.first != nil
	}

	var hasEnvironmentMetrics: Bool {
		telemetries?.filter { telemetry in
			(telemetry as AnyObject).metricsType == 1
		}.first != nil
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
		let fifteenMinutesAgo = Calendar.current.date(byAdding: .minute, value: -15, to: .now)
		if lastHeard?.compare(fifteenMinutesAgo!) == .orderedDescending {
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
