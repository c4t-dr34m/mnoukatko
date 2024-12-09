/*
Mňoukátko - a Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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
import MapKit
import SwiftUI

struct MeshMapContent: MapContent {
	@StateObject
	var appState = AppState.shared
	@Binding
	var selectedPosition: PositionEntity?
	@Binding
	var showLabelsForOffline: Bool
	var onAppear: ((_ nodeName: String) -> Void)?
	var onDisappear: ((_ nodeName: String) -> Void)?

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@FetchRequest(
		fetchRequest: PositionEntity.allPositionsFetchRequest(),
		animation: .easeIn
	)
	private var positions: FetchedResults<PositionEntity>

	@MapContentBuilder
	var body: some MapContent {
		ForEach(positions, id: \.nodePosition?.num) { position in
			if
				let node = position.nodePosition,
				let nodeName = node.user?.shortName
			{
				let centerMarker = node.isOnline || !showLabelsForOffline

				Annotation(
					coordinate: position.coordinate,
					anchor: centerMarker ? .center : .leading
				) {
					avatar(for: node, name: nodeName)
						.onAppear {
							onAppear?(nodeName)
						}
						.onDisappear {
							onDisappear?(nodeName)
						}
						.onTapGesture {
							selectedPosition = selectedPosition == position ? nil : position
						}
				} label: {
					// no label
				}
				.tag(position.time)
				.annotationTitles(.automatic)
				.annotationSubtitles(.automatic)
				.mapOverlayLevel(level: .aboveLabels)
			}
		}
	}

	@ViewBuilder
	private func avatar(for node: NodeInfoEntity, name: String) -> some View {
		if node.isOnline {
			ZStack(alignment: .top) {
				AvatarNode(
					node,
					showTemperature: true,
					size: 48
				)
				.padding(.all, 8)

				if node.hopsAway >= 0 {
					let visible = node.hopsAway == 0

					HStack(spacing: 0) {
						Spacer()
						Image(systemName: visible ? "eye.circle.fill" : "\(node.hopsAway).circle.fill")
							.font(.system(size: 20))
							.background(node.color)
							.foregroundColor(node.color.isLight ? .black.opacity(0.5) : .white.opacity(0.5))
							.clipShape(Circle())
					}
				}
			}
			.frame(width: 64, height: 64)
		}
		else {
			if showLabelsForOffline {
				HStack(alignment: .center, spacing: 4) {
					offlineNodeDot(for: node)

					if let name = node.user?.longName {
						Text(name)
							.font(.system(size: 10, weight: .regular, design: .rounded))
							.foregroundColor(.primary)
					}
				}
				.padding(.all, 4)
				.overlay(
					RoundedRectangle(cornerRadius: 8)
						.stroke(.primary, lineWidth: 1)
						.background(colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.4))
				)
				.clipShape(
					RoundedRectangle(cornerRadius: 8)
				)
			}
			else {
				offlineNodeDot(for: node)
			}
		}
	}

	@ViewBuilder
	private func offlineNodeDot(for node: NodeInfoEntity) -> some View {
		ZStack(alignment: .center) {
			RoundedRectangle(cornerRadius: 4)
				.frame(width: 12, height: 12)
				.foregroundColor(colorScheme == .dark ? .black : .white)
			RoundedRectangle(cornerRadius: 2)
				.frame(width: 8, height: 8)
				.foregroundColor(node.color)
		}
	}
}
