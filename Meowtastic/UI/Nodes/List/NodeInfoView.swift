import SwiftUI

struct NodeInfoView: View {
	var modemPreset: ModemPresets = ModemPresets(
		rawValue: UserDefaults.modemPreset
	) ?? ModemPresets.longFast

	@ObservedObject
	var node: NodeInfoEntity

	var body: some View {
		HStack(alignment: .top, spacing: 16) {
			Avatar(
				node.user?.shortName,
				background: node.color,
				size: 72
			)

			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .top, spacing: 0) {
					if let longName = node.user?.longName {
						Text(longName)
							.lineLimit(1)
							.font(.title)
							.minimumScaleFactor(0.5)
					}
					else {
						Text("Node Without a Name")
							.lineLimit(1)
							.font(.title)
							.foregroundColor(.gray)
							.minimumScaleFactor(0.5)
					}

					Spacer()
				}

				if node.snr != 0 && !node.viaMqtt {
					LoRaSignalMeterView(
						snr: node.snr,
						rssi: node.rssi,
						preset: modemPreset,
						withLabels: true
					)
				}

				BatteryGaugeView(
					node: node,
					withLabels: true
				)
			}
			.frame(maxWidth: .infinity)
		}
	}

	init(node: NodeInfoEntity) {
		self.node = node
	}
}