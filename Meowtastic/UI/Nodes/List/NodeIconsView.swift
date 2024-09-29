import CoreLocation
import Foundation
import SwiftUI

struct NodeIconsView: View {
	var connectedNode: Int64

	@ObservedObject
	var node: NodeInfoEntity

	private let detailIconSize: CGFloat = 16
	private let detailIconSpacing: CGFloat = 6

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@EnvironmentObject
	private var locationManager: LocationManager
	@State
	private var telemetryHistory = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .day, value: -5, to: .now)!
	)

	private var nodePosition: PositionEntity? {
		node.positions?.lastObject as? PositionEntity
	}
	private var nodeEnvironment: TelemetryEntity? {
		guard
			let history = node
				.telemetries?
				.filtered(
					using: NSPredicate(format: "metricsType == 1")
				)
				.array as? [TelemetryEntity]
		else {
			return nil
		}

		return history.last(where: { measurement in
			if let time = measurement.time, time >= telemetryHistory {
				return true
			}
			else {
				return false
			}
		})
	}

	@ViewBuilder
	var body: some View {
		let detailInfoIconFont = Font.system(size: 14, weight: .regular, design: .rounded)
		let detailHopsIconFont = Font.system(size: 10, weight: .semibold, design: .rounded)

		HStack(alignment: .center, spacing: detailIconSpacing) {
			if let role = DeviceRoles(rawValue: Int(node.user?.role ?? 0))?.systemName {
				Image(systemName: role)
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
					.frame(width: detailIconSize)
			}

			if connectedNode != node.num {
				if node.viaMqtt {
					divider

					Image(systemName: "network")
						.font(detailInfoIconFont)
						.foregroundColor(.gray)
						.frame(width: detailIconSize)
				}

				if node.hopsAway == 0 {
					divider

					Image(systemName: "eye")
						.font(detailInfoIconFont)
						.foregroundColor(.gray)
						.frame(width: detailIconSize)
				}
				else {
					divider

					ZStack(alignment: .top) {
						let badgeOffset: CGFloat = 7

						Image(systemName: "arrowshape.bounce.forward")
							.font(detailInfoIconFont)
							.foregroundColor(.gray)
							.frame(width: detailIconSize)
							.padding(.leading, badgeOffset)

						HStack(spacing: 0) {
							Image(systemName: "\(node.hopsAway).circle")
								.font(detailHopsIconFont)
								.foregroundColor(.gray)
								.background(Color.listBackground(for: colorScheme))
								.clipShape(
									Circle()
								)

							Spacer()
						}
						.frame(width: detailIconSize + badgeOffset)
					}
				}
			}

			if node.hasTraceRoutes {
				divider

				Image(systemName: "signpost.right.and.left.fill")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
					.frame(width: detailIconSize)
			}

			if node.isStoreForwardRouter {
				divider

				Image(systemName: "envelope.arrow.triangle.branch")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
					.frame(width: detailIconSize)
			}

			if node.hasDetectionSensorMetrics {
				divider

				Image(systemName: "sensor")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
					.frame(width: detailIconSize)
			}

			locationInfo
			environmentInfo
		}
	}

	@ViewBuilder
	private var locationInfo: some View {
		if node.hasPositions {
			let detailInfoIconFont = Font.system(size: 14, weight: .regular, design: .rounded)
			let detailInfoTextFont = Font.system(size: 12, weight: .semibold, design: .rounded)

			divider

			if
				let currentCoordinate = locationManager.lastKnownLocation?.coordinate,
				let lastCoordinate = (node.positions?.lastObject as? PositionEntity)?.coordinate
			{
				let myLocation = CLLocation(
					latitude: currentCoordinate.latitude,
					longitude: currentCoordinate.longitude
				)
				let location = CLLocation(
					latitude: lastCoordinate.latitude,
					longitude: lastCoordinate.longitude
				)
				let distance = location.distance(from: myLocation) / 1000 // km
				let distanceFormatted = String(format: "%.0f", distance) + "km"

				Image(systemName: "mappin.and.ellipse")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)

				Text(distanceFormatted)
					.font(detailInfoTextFont)
					.lineLimit(1)
					.foregroundColor(.gray)
			}
			else {
				Image(systemName: "mappin.and.ellipse")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
					.frame(width: detailIconSize)
			}
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var environmentInfo: some View {
		if let nodeEnvironment {
			let detailInfoIconFont = Font.system(size: 14, weight: .regular, design: .rounded)
			let detailInfoTextFont = Font.system(size: 12, weight: .semibold, design: .rounded)

			divider

			let temp = nodeEnvironment.temperature
			let tempFormatted = String(format: "%.0f", temp) + "°C"

			if temp < 10 {
				Image(systemName: "thermometer.low")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
			}
			else if temp < 25 {
				Image(systemName: "thermometer.medium")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
			}
			else {
				Image(systemName: "thermometer.high")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
			}

			Text(tempFormatted)
				.font(detailInfoTextFont)
				.lineLimit(1)
				.foregroundColor(.gray)
		}
	}

	@ViewBuilder
	private var divider: some View {
		Divider()
			.frame(height: 16)
			.foregroundColor(.gray)
	}
}
