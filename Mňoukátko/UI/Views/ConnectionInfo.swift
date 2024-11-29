/*
Mňoukátko - the Meshtastic® client

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

struct ConnectionInfo: View {
	private var mqttChannelInfo = false
	private var mqttUplinkEnabled = false
	private var mqttDownlinkEnabled = false

	@EnvironmentObject
	private var bleManager: BLEManager
	@State
	private var rssiTimer: Timer?
	private var infoColor: Color {
		if let info = bleManager.infoLastChanged {
			let diff = info.distance(to: .now)

			if diff <= 90 {
				return .green
			}
			else if diff <= 300 {
				return .orange
			}
			else {
				return .gray
			}
		}
		else {
			return .gray
		}
	}
	private var infoColorBackground: Color {
		infoColor.opacity(0.3)
	}
	private var singleClip: UnevenRoundedRectangle {
		let corners = RectangleCornerRadii(
			topLeading: 12,
			bottomLeading: 12,
			bottomTrailing: 12,
			topTrailing: 12
		)

		return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
	}
	private var leadingClip: UnevenRoundedRectangle {
		let corners = RectangleCornerRadii(
			topLeading: 2,
			bottomLeading: 2,
			bottomTrailing: 12,
			topTrailing: 12
		)

		return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
	}
	private var centerClip: UnevenRoundedRectangle {
		if bleManager.getConnectedDevice() == nil {
			let corners = RectangleCornerRadii(
				topLeading: 2,
				bottomLeading: 2,
				bottomTrailing: 12,
				topTrailing: 12
			)

			return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
		}
		else {
			let corners = RectangleCornerRadii(
				topLeading: 2,
				bottomLeading: 2,
				bottomTrailing: 2,
				topTrailing: 2
			)

			return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
		}
	}
	private var trailingClip: UnevenRoundedRectangle {
		let corners = RectangleCornerRadii(
			topLeading: 12,
			bottomLeading: 12,
			bottomTrailing: 2,
			topTrailing: 2
		)

		return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
	}

	@ViewBuilder
	var body: some View {
		if bleManager.isSwitchedOn {
			if bleManager.isConnected {
				HStack(spacing: 2) {
					if let connectedDevice = bleManager.getConnectedDevice() {
						SignalStrengthIndicator(
							signalStrength: connectedDevice.getSignalStrength(),
							size: 16,
							color: .green
						)
						.padding(.vertical, 8)
						.padding(.leading, 12)
						.padding(.trailing, 8)
						.background(.green.opacity(0.3))
						.clipShape(trailingClip)
						.onAppear {
							rssiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
								connectedDevice.peripheral.readRSSI()
							}
						}
						.onDisappear {
							rssiTimer?.invalidate()
						}
					}
					else {
						EmptyView()
					}

					if let infoLastChanged = bleManager.infoLastChanged {
						let diff = infoLastChanged.distance(to: .now)

						HStack {
							if diff < 60 {
								Image(systemName: "bolt.horizontal.fill")
									.resizable()
									.scaledToFit()
									.frame(width: 16, height: 16)
									.foregroundColor(infoColor)

								Text(String(format: "%.0f", diff) + "\"")
									.font(
										.system(size: 12, weight: .bold, design: .rounded)
										.monospaced()
									)
									.lineLimit(1)
									.foregroundColor(infoColor)
									.transition(.slide)
									.id("info_seconds")
							}
							else {
								Image(systemName: "bolt.horizontal")
									.resizable()
									.scaledToFit()
									.frame(width: 16, height: 16)
									.foregroundColor(infoColor)

								Text(String(format: "%.0f", diff / 60) + "'")
									.font(
										.system(size: 12, weight: .bold, design: .rounded)
										.monospaced()
									)
									.lineLimit(1)
									.foregroundColor(infoColor)
									.transition(.slide)
									.id("info_minutes")
							}
						}
						.padding(.vertical, 8)
						.padding(.horizontal, 8)
						.background(infoColorBackground)
						.clipShape(centerClip)
					}

					if mqttChannelInfo {
						MQTTChannelIcon(
							connected: bleManager.mqttConnected,
							uplink: mqttUplinkEnabled,
							downlink: mqttDownlinkEnabled
						)
						.clipShape(leadingClip)
					}
					else {
						MQTTConnectionIcon(
							connected: bleManager.mqttConnected
						)
						.clipShape(leadingClip)
					}
				}
			}
			else if bleManager.lastConnectionError.count > 0 {
				deviceIcon("exclamationmark.triangle.fill", color: .red)
					.clipShape(singleClip)
			}
			else {
				deviceIcon("antenna.radiowaves.left.and.right.slash", color: .accentColor)
					.clipShape(singleClip)
			}
		}
		else {
			deviceIcon("power", color: .red)
				.clipShape(singleClip)
		}
	}

	init() {
		self.mqttChannelInfo = false
	}

	init(
		mqttUplinkEnabled: Bool = false,
		mqttDownlinkEnabled: Bool = false
	) {
		self.mqttUplinkEnabled = mqttUplinkEnabled
		self.mqttDownlinkEnabled = mqttDownlinkEnabled

		self.mqttChannelInfo = true
	}

	@ViewBuilder
	private func deviceIcon(_ resource: String, color: Color) -> some View {
		Image(systemName: resource)
			.resizable()
			.scaledToFit()
			.frame(width: 16, height: 16)
			.foregroundColor(color)
			.padding(.vertical, 8)
			.padding(.horizontal, 16)
			.background(color.opacity(0.3))
	}
}
