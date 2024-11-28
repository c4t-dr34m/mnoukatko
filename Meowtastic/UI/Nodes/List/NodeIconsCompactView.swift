import CoreLocation
import Foundation
import SwiftUI

struct NodeIconsCompactView: View {
	var connectedNode: Int64

	@ObservedObject
	var node: NodeInfoEntity

	private let detailIconSize: CGFloat = 12
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
		let detailInfoIconFont = Font.system(size: 12, weight: .regular, design: .rounded)
		let detailHopsIconFont = Font.system(size: 8, weight: .semibold, design: .rounded)

		HStack(alignment: .center, spacing: detailIconSpacing) {
			if connectedNode != node.num {
				divider

				if let user = node.user, user.pkiEncrypted {
					switch KeyMatch.fromInt(user.keyMatch) {
					case .notSet:
						Image(systemName: "lock.open.trianglebadge.exclamationmark")
							.font(detailInfoIconFont)
							.foregroundColor(.gray)
							.frame(width: detailIconSize)

					case .notMatching:
						Image(systemName: "lock.slash")
							.font(detailInfoIconFont)
							.foregroundColor(.gray)
							.frame(width: detailIconSize)

					case .matching:
						Image(systemName: "lock")
							.font(detailInfoIconFont)
							.foregroundColor(.gray)
							.frame(width: detailIconSize)
					}
				}
				else {
					Image(systemName: "lock.open")
						.font(detailInfoIconFont)
						.foregroundColor(.gray)
						.frame(width: detailIconSize)
				}

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
		}
	}

	@ViewBuilder
	private var locationInfo: some View {
		if node.hasPositions {
			let detailInfoIconFont = Font.system(size: 12, weight: .regular, design: .rounded)

			divider

			Image(systemName: "mappin.and.ellipse")
				.font(detailInfoIconFont)
				.foregroundColor(.gray)
				.frame(width: detailIconSize)
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var environmentInfo: some View {
		if nodeEnvironment != nil {
			let detailInfoIconFont = Font.system(size: 12, weight: .regular, design: .rounded)

			divider

			Image(systemName: "thermometer.variable")
				.font(detailInfoIconFont)
				.foregroundColor(.gray)
				.frame(width: detailIconSize)
		}
	}

	@ViewBuilder
	private var divider: some View {
		Divider()
			.frame(height: 10)
			.foregroundColor(.gray)
	}
}
