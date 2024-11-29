/*
Mňoukátko - the Meshtastic® client

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
import CoreLocation
import MapKit
import SwiftUI

struct NodeListItem: View {
	private let connected: Bool
	private let modemPreset: ModemPresets
	private let node: NodeInfoEntity
	private let detailNameFont = Font.system(size: 20, weight: .semibold, design: .rounded)
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailIconWidth: CGFloat = 20

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@EnvironmentObject
	private var locationManager: LocationManager
	@EnvironmentObject
	private var connectedDevice: CurrentDevice

	var body: some View {
		NavigationLink {
			NavigationLazyView(
				NodeDetail(node: node)
			)
		} label: {
			HStack(alignment: .top) {
				avatar

				VStack(alignment: .leading, spacing: 8) {
					Spacer()
						.frame(height: 2)

					name

					if node.isOnline, let device = connectedDevice.device {
						NodeIconsView(connectedNode: device.num, node: node)
					}
					else {
						lastHeard
					}
				}

				Spacer()
			}
		}
	}

	@ViewBuilder
	private var avatar: some View {
		ZStack(alignment: .top) {
			AvatarNode(
				node,
				showLastHeard: node.isOnline,
				size: 64
			)
			.padding([.top, .bottom, .trailing], 10)

			if connected {
				HStack(spacing: 0) {
					Spacer()
					Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(node.isOnline ? node.color : Color.gray.opacity(0.2))
						.background(
							Circle()
								.foregroundColor(.listBackground(for: colorScheme))
						)
				}
			}
			else if node.favorite {
				HStack(spacing: 0) {
					Spacer()
					Image(systemName: "star.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(.yellow)
						.background(
							Circle()
								.foregroundColor(.listBackground(for: colorScheme))
						)
				}
			}
		}
		.frame(width: 80, height: 80)
	}

	@ViewBuilder
	private var name: some View {
		Text(node.user?.longName ?? "Unknown node")
			.font(detailNameFont)
			.lineLimit(2)
			.minimumScaleFactor(0.5)
	}

	@ViewBuilder
	private var lastHeard: some View {
		if
			let lastHeard = node.lastHeard,
			lastHeard.timeIntervalSince1970 > 0
		{
			HStack {
				Image(systemName: node.isOnline ? "clock.badge.checkmark" : "clock.badge.exclamationmark")
					.frame(width: detailIconWidth)
					.font(detailInfoFont)
					.foregroundColor(node.isOnline ? .green : .gray)

				Text(lastHeard.relative())
					.font(detailInfoFont)
					.lineLimit(1)
					.minimumScaleFactor(0.5)
					.foregroundColor(.gray)
			}
		}
		else {
			HStack {
				Image(systemName: "clock.badge.questionmark")
					.font(detailInfoFont)
					.foregroundColor(.gray)

				Text("No idea")
					.font(detailInfoFont)
					.foregroundColor(.gray)
			}
		}
	}

	init(
		node: NodeInfoEntity,
		connected: Bool
	) {
		self.node = node
		self.connected = connected
		self.modemPreset = ModemPresets(rawValue: UserDefaults.modemPreset) ?? ModemPresets.longFast
	}
}
