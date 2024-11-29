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
import SwiftUI

struct NodeListConnectedItem: View {
	private let coreDataTools = CoreDataTools()
	private let detailNameFont = Font.system(size: 20, weight: .semibold, design: .rounded)
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailIconSize: CGFloat = 16

	@Environment(\.managedObjectContext)
	private var context
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@State
	private var telemetryHistory = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .day, value: -1, to: .now)!
	)

	private var connectedNodeNum: Int64 {
		Int64(connectedDevice.device?.num ?? 0)
	}
	private var connectedNode: NodeInfoEntity? {
		coreDataTools.getNodeInfo(
			id: connectedNodeNum,
			context: context
		)
	}

	@ViewBuilder
	var body: some View {
		NavigationLink {
			if let connectedNode {
				NodeDetail(node: connectedNode)
			}
			else {
				Connect()
			}
		} label: {
			HStack(alignment: .top) {
				connectedNodeAvatar

				VStack(alignment: .leading, spacing: 4) {
					Spacer()
						.frame(height: 2)

					if let connectedNode {
						Text(connectedNode.user?.longName ?? "Unknown node")
							.lineLimit(2)
							.font(detailNameFont)

						BatteryView(
							node: connectedNode,
							withLabels: true
						)

						let deviceMetrics = connectedNode.telemetries?.filtered(
							using: NSPredicate(format: "metricsType == 0")
						)
						let mostRecent = deviceMetrics?.lastObject as? TelemetryEntity

						if let channelUtil = mostRecent?.channelUtilization {
							let chUtilFormatted = String(format: "%.2f", channelUtil) + "%"

							HStack {
								Image(systemName: "arrow.left.arrow.right.circle.fill")
									.font(detailInfoFont)
									.foregroundColor(.gray)
									.frame(width: 18)

								Text("Channel: " + chUtilFormatted)
									.font(detailInfoFont)
									.foregroundColor(.gray)
							}
						}

						if let airUtilTx = mostRecent?.airUtilTx {
							let airUtilFormatted = String(format: "%.2f", airUtilTx) + "%"

							HStack {
								Image(systemName: "wave.3.right.circle.fill")
									.font(detailInfoFont)
									.foregroundColor(.gray)
									.frame(width: 18)

								Text("Air Time: " + airUtilFormatted)
									.font(detailInfoFont)
									.foregroundColor(.gray)
							}
						}

						let nodeEnvironment: TelemetryEntity? = {
							guard
								let history = connectedNode
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
						}()

						if let nodeEnvironment {
							HStack {
								let temp = nodeEnvironment.temperature
								let dateFormatted = nodeEnvironment.time?.relative()
								let tempFormatted = String(format: "%.0f", temp) + "°C"

								if temp < 10 {
									Image(systemName: "thermometer.low")
										.font(detailInfoFont)
										.foregroundColor(.gray)
										.frame(width: 18)
								}
								else if temp < 25 {
									Image(systemName: "thermometer.medium")
										.font(detailInfoFont)
										.foregroundColor(.gray)
										.frame(width: 18)
								}
								else {
									Image(systemName: "thermometer.high")
										.font(detailInfoFont)
										.foregroundColor(.gray)
										.frame(width: 18)
								}

								HStack(spacing: 4) {
									Text(tempFormatted)
										.font(detailInfoFont)
										.foregroundColor(.gray)

									if let dateFormatted {
										Text("(\(dateFormatted))")
											.font(detailInfoFont)
											.foregroundColor(.gray)
									}
								}
							}
						}
					}
					else {
						Text("Not connected")
							.lineLimit(1)
							.font(detailNameFont)
					}
				}
				.frame(alignment: .leading)
			}
			.padding(.bottom, 8)
		}
	}

	@ViewBuilder
	private var connectedNodeAvatar: some View {
		ZStack(alignment: .top) {
			if let connectedNode {
				AvatarNode(
					connectedNode,
					size: 64
				)
				.padding([.top, .bottom, .trailing], 10)

				HStack(spacing: 0) {
					Spacer()

					Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(connectedNode.color)
						.background(
							Circle()
								.foregroundColor(.listBackground(for: colorScheme))
						)
				}
			}
			else {
				AvatarAbstract(
					size: 64
				)
				.padding([.top, .bottom, .trailing], 10)
			}
		}
		.frame(width: 80, height: 80)
	}
}
