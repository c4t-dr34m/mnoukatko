/*
Mňoukátko - a Meshtastic® client

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
import SwiftUI

struct AvatarNode: View {
	private let size: CGFloat
	private let ignoreOffline: Bool
	private let showTemperature: Bool
	private let showLastHeard: Bool
	// swiftlint:disable:next large_tuple
	private let corners: (Bool, Bool, Bool, Bool)?
	private let light: UnitPoint

	@ObservedObject
	private var node: NodeInfoEntity
	@State
	private var last5min = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .minute, value: -5, to: .now)!
	)
	@State
	private var last10min = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .minute, value: -10, to: .now)!
	)
	private var name: String? {
		node.user?.shortName
	}
	private var foregroundColor: Color {
		backgroundColor.isLight() ? .black : .white
	}
	private var backgroundColor: Color {
		if node.isOnline || ignoreOffline {
			return node.color
		}
		else {
			return .gray.opacity(0.4)
		}
	}
	private var background: RadialGradient {
		let gradientColors: [Color]
		if node.isOnline || ignoreOffline {
			gradientColors = [
				Color(
					uiColor: backgroundColor.uiColor
						.lightness(delta: +0.1)
				),
				Color(
					uiColor: backgroundColor.uiColor
						.lightness(delta: -0.1)
						.saturation(delta: +0.3)
				)
			]
		}
		else {
			gradientColors = [
				Color(
					uiColor: backgroundColor.uiColor
						.lightness(delta: +0.1)
				),
				Color(
					uiColor: backgroundColor.uiColor
						.lightness(delta: -0.1)
				)
			]
		}

		return RadialGradient(
			colors: gradientColors,
			center: light,
			startRadius: size / 4,
			endRadius: size
		)
	}
	private var temperature: Double? {
		let nodeEnvironment = node
			.telemetries?
			.filtered(
				using: NSPredicate(format: "metricsType == 1")
			)
			.lastObject as? TelemetryEntity

		guard let temperature = nodeEnvironment?.temperature else {
			return nil
		}

		return Double(temperature)
	}

	private var radii: RectangleCornerRadii {
		let radius = size / 4

		if let corners {
			return RectangleCornerRadii(
				topLeading: corners.0 ? radius : 0,
				bottomLeading: corners.1 ? radius : 0,
				bottomTrailing: corners.2 ? radius : 0,
				topTrailing: corners.3 ? radius : 0
			)
		}
		else {
			return RectangleCornerRadii(
				topLeading: radius,
				bottomLeading: radius,
				bottomTrailing: radius,
				topTrailing: radius
			)
		}
	}

	var body: some View {
		ZStack(alignment: .center) {
			if let name = name, !name.isEmpty {
				Text(name)
					.font(Font.custom("Iosevka-Fixed-Heavy", size: 128))
					.foregroundColor(foregroundColor)
					.lineLimit(1)
					.minimumScaleFactor(0.01)
					.padding(.vertical, size / 8)
					.padding(.horizontal, size / 14)
					.frame(width: size, height: size)
			}
			else {
				Image(systemName: "questionmark")
					.resizable()
					.scaledToFit()
					.foregroundColor(foregroundColor)
					.padding(.vertical, size / 8)
					.padding(.horizontal, size / 14)
					.frame(width: size, height: size)
			}

			if showLastHeard {
				if
					node.isOnline || ignoreOffline,
					let lastHeard = node.lastHeard,
					lastHeard.timeIntervalSince1970 > 0
				{
					HStack(alignment: .center, spacing: 2) {
						Image(systemName: "clock")
							.font(.system(size: size / 8, weight: .semibold, design: .rounded))
							.foregroundColor(backgroundColor.opacity(0.8))

						let diff = lastHeard.distance(to: .now) // seconds
						if diff < 10 { // about right now
							Text("now")
								.font(.system(size: size / 6, weight: .semibold, design: .rounded))
								.foregroundColor(backgroundColor.opacity(0.8))
								.lineLimit(1)
								.minimumScaleFactor(0.2)
						}
						else if diff < 60 { // less than a minute
							Text(String(format: "%.0f", diff) + "s")
								.font(.system(size: size / 6, weight: .bold, design: .rounded))
								.foregroundColor(backgroundColor.opacity(0.8))
								.lineLimit(1)
								.minimumScaleFactor(0.2)
						}
						else if diff < (60 * 90) { // less than 90 minutes
							Text(String(format: "%.0f", diff / 60) + "m")
								.font(.system(size: size / 6, weight: .bold, design: .rounded))
								.foregroundColor(backgroundColor.opacity(0.8))
								.lineLimit(1)
								.minimumScaleFactor(0.2)
						}
						else if diff < (24 * 60 * 90) { // less than a day
							Text(String(format: "%.0f", diff / (60 * 60)) + "h")
								.font(.system(size: size / 6, weight: .bold, design: .rounded))
								.foregroundColor(backgroundColor.opacity(0.8))
								.lineLimit(1)
								.minimumScaleFactor(0.2)
						}
						else {
							Text(String(format: "%.0f", diff / (24 * 60 * 60)) + "d")
								.font(.system(size: size / 6, weight: .bold, design: .rounded))
								.foregroundColor(backgroundColor.opacity(0.8))
								.lineLimit(1)
								.minimumScaleFactor(0.2)
						}
					}
					.padding(.leading, size / 16)
					.padding(.trailing, size / 8)
					.padding(.vertical, size / 36)
					.background(foregroundColor.opacity(0.8))
					.clipShape(
						UnevenRoundedRectangle(
							cornerRadii: RectangleCornerRadii(topLeading: 4)
						)
					)
					.frame(width: size, height: size, alignment: .bottomTrailing)
				}
				else {
					Image(systemName: "antenna.radiowaves.left.and.right.slash")
						.font(.system(size: size / 8, weight: .semibold, design: .rounded))
						.foregroundColor(backgroundColor.opacity(0.8))
						.padding(.horizontal, size / 8)
						.padding(.vertical, size / 36)
						.background(foregroundColor.opacity(0.8))
						.clipShape(
							UnevenRoundedRectangle(
								cornerRadii: RectangleCornerRadii(topLeading: 4)
							)
						)
						.frame(width: size, height: size, alignment: .bottomTrailing)
				}
			}
			else if
				showTemperature,
				node.isOnline,
				let temperature
			{
				let tempFormatted = String(format: "%.0f", temperature)

				HStack(alignment: .center, spacing: 2) {
					Image(systemName: "thermometer.variable")
						.font(.system(size: size / 8, weight: .semibold, design: .rounded))
						.foregroundColor(backgroundColor.opacity(0.8))

					Text(tempFormatted)
						.font(.system(size: size / 6, weight: .bold, design: .rounded))
						.foregroundColor(backgroundColor.opacity(0.8))
						.lineLimit(1)
				}
				.padding(.horizontal, size / 8)
				.padding(.vertical, size / 36)
				.background(foregroundColor.opacity(0.8))
				.clipShape(
					UnevenRoundedRectangle(
						cornerRadii: RectangleCornerRadii(topLeading: 4)
					)
				)
				.frame(width: size, height: size, alignment: .bottomTrailing)
			}
		}
		.background(background)
		.clipShape(
			UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
		)
	}

	init(
		_ node: NodeInfoEntity,
		ignoreOffline: Bool = false,
		showTemperature: Bool = false,
		showLastHeard: Bool = false,
		size: CGFloat = 45,
		// swiftlint:disable:next large_tuple
		corners: (Bool, Bool, Bool, Bool)? = nil,
		light: UnitPoint = .top
	) {
		self.node = node
		self.ignoreOffline = ignoreOffline
		self.showTemperature = showTemperature
		self.showLastHeard = showLastHeard
		self.size = size
		self.corners = corners
		self.light = light
	}
}
