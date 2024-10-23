import SwiftUI

struct ConnectionInfo: View {
	private var mqttChannelInfo = false
	private var mqttUplinkEnabled = false
	private var mqttDownlinkEnabled = false

	@EnvironmentObject
	private var bleManager: BLEManager
	@State
	private var rssiTimer: Timer?
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
		if bleManager.getConnectedDevice() == nil {
			return singleClip
		}
		else {
			let corners = RectangleCornerRadii(
				topLeading: 2,
				bottomLeading: 2,
				bottomTrailing: 12,
				topTrailing: 12
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
						.padding(8)
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
			.padding(8)
			.background(color.opacity(0.3))
	}
}
