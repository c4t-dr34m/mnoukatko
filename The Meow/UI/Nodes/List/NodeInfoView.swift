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

struct NodeInfoView: View {
	var modemPreset: ModemPresets = ModemPresets(
		rawValue: UserDefaults.modemPreset
	) ?? ModemPresets.longFast

	@ObservedObject
	var node: NodeInfoEntity

	private let detailNameFont = Font.system(size: 20, weight: .semibold, design: .rounded)

	var body: some View {
		HStack(alignment: .top, spacing: 16) {
			AvatarNode(
				node,
				size: 72
			)

			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .top, spacing: 0) {
					if let longName = node.user?.longName {
						Text(longName)
							.lineLimit(1)
							.font(detailNameFont)
							.minimumScaleFactor(0.5)
					}
					else {
						Text("Node Without a Name")
							.lineLimit(1)
							.font(detailNameFont)
							.foregroundColor(.gray)
							.minimumScaleFactor(0.5)
					}

					Spacer()
				}

				if node.snr != 0, node.rssi != 0 {
					LoraSignalView(
						snr: node.snr,
						rssi: node.rssi,
						preset: modemPreset,
						withLabels: true
					)
				}

				BatteryView(
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
