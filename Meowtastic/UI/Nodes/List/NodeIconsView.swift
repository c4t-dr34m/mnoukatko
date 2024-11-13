import CoreLocation
import Foundation
import SwiftUI

struct NodeIconsView: View {
	private let detailIconSize: CGFloat = 18
	private let detailIconSpacing: CGFloat = 12
	private let detailInfoTextFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailInfoIconFont = Font.system(size: 16, weight: .regular, design: .rounded)
	private let detailHopsIconFont = Font.system(size: 10, weight: .semibold, design: .rounded)

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@EnvironmentObject
	private var locationManager: LocationManager
	@ObservedObject
	private var node: NodeInfoEntity
	@State
	private var telemetryHistory = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .day, value: -5, to: .now)!
	)
	private var connectedNode: Int64
	private var modemPreset: ModemPresets = ModemPresets(
		rawValue: UserDefaults.modemPreset
	) ?? ModemPresets.longFast
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
		VStack(alignment: .leading, spacing: 8) {
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

						if
							!node.viaMqtt,
							let signal = LoRaSignal.getSignalStrength(snr: node.snr, rssi: node.rssi, preset: modemPreset)
						{
							ZStack(alignment: .center) {
								SignalStrengthIndicator(
									signalStrength: signal,
									size: detailIconSize - 2,
									color: .gray,
									thin: true
								)
							}
							.frame(width: detailIconSize)
						}
						else {
							Image(systemName: "eye")
								.font(detailInfoIconFont)
								.foregroundColor(.gray)
								.frame(width: detailIconSize)
						}
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
			}

			if node.hasPositions || nodeEnvironment != nil {
				HStack(alignment: .center, spacing: detailIconSpacing) {
					locationInfo

					if node.hasPositions, nodeEnvironment != nil {
						divider
					}

					environmentInfo
				}
			}
		}
	}

	@ViewBuilder
	private var locationInfo: some View {
		if node.hasPositions {
			if
				let currentCoordinate = locationManager.getLocation()?.coordinate,
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
				let bearing = myLocation.bearing(to: location)
				let distance = location.distance(from: myLocation) / 1000 // km
				let distanceFormatted = String(format: "%.0f", distance) + "km"

				Image(systemName: "mappin.and.ellipse")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)

				Text(distanceFormatted)
					.font(detailInfoTextFont)
					.lineLimit(1)
					.foregroundColor(.gray)

				Image(systemName: "location.north.circle.fill")
					.font(detailInfoIconFont)
					.foregroundColor(.gray)
					.rotationEffect(
						Angle(degrees: bearing)
					)
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

	init(connectedNode: Int64, node: NodeInfoEntity) {
		self.connectedNode = connectedNode
		self.node = node
	}
}
