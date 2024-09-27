import CoreLocation
import MapKit
import SwiftUI

struct NodeListItem: View {
	private let connected: Bool
	private let modemPreset: ModemPresets
	private let node: NodeInfoEntity
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailIconSize: CGFloat = 16
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
					name
					lastHeard

					if node.isOnline, let device = connectedDevice.device {
						hardwareInfo

						NodeIconListView(connectedNode: device.num, node: node)
							.padding(.vertical, 4)
							.padding(.horizontal, 12)
							.overlay(
								RoundedRectangle(cornerRadius: 16)
									.stroke(.gray, lineWidth: 1)
							)
							.clipShape(
								RoundedRectangle(cornerRadius: 16)
							)
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
				size: 64
			)
			.padding([.top, .bottom, .trailing], 10)

			if connected {
				HStack(spacing: 0) {
					Spacer()
					Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(colorScheme == .dark ? .white : .gray)
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
						.foregroundColor(colorScheme == .dark ? .white : .gray)
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
		Text(node.user?.longName ?? "Unknown")
			.fontWeight(.medium)
			.font(.title2)
			.lineLimit(1)
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

	@ViewBuilder
	private var hardwareInfo: some View {
		if let hwModel = node.user?.hwModel {
			HStack {
				Image(systemName: "flipphone")
					.frame(width: detailIconWidth)
					.font(detailInfoFont)
					.foregroundColor(.gray)

				Text(hwModel)
					.font(detailInfoFont)
					.foregroundColor(.gray)
			}
		}
		else {
			EmptyView()
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
