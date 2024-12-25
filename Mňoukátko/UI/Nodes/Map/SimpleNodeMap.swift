/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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

struct SimpleNodeMap: View {
	private let mapStyle = MapStyle.standard(elevation: .flat)

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@Environment(\.managedObjectContext)
	private var context
	@Namespace
	private var mapScope
	@State
	private var position = MapCameraPosition.automatic
	private var node: NodeInfoEntity
	private var positions: [PositionEntity]? {
		node.positions?.array as? [PositionEntity]
	}
	private var nodeColor: Color {
		if colorScheme == .dark {
			.white
		}
		else {
			.black
		}
	}

	@ViewBuilder
	var body: some View {
		if node.hasPositions {
			map
		}
	}

	@ViewBuilder
	private var map: some View {
		MapReader { _ in
			Map(
				position: $position,
				bounds: MapCameraBounds(minimumDistance: 100, maximumDistance: .infinity),
				scope: mapScope
			) {
				if let latest = positions?.first(where: { $0.latest }) {
					if
						let radius = PositionPrecision(rawValue: Int(latest.precisionBits))?.precisionMeters,
						radius > 10.0
					{
						MapCircle(center: latest.coordinate, radius: radius)
							.foregroundStyle(
								Color(nodeColor).opacity(0.25)
							)
							.stroke(nodeColor.opacity(0.5), lineWidth: 2)
					}

					Annotation(
						coordinate: latest.coordinate,
						anchor: .center
					) {
						Image(systemName: "flipphone")
							.font(.system(size: 32))
							.foregroundColor(nodeColor)
					} label: {
						// nothing
					}
					.tag(latest.time)
				}
			}
			.mapScope(mapScope)
			.mapStyle(mapStyle)
			.mapControlVisibility(.hidden)
			.onAppear {
				if
					let lastCoordinate = (node.positions?.lastObject as? PositionEntity)?.coordinate
				{
					position = .camera(
						MapCamera(
							centerCoordinate: lastCoordinate,
							distance: 500,
							heading: 0,
							pitch: 80
						)
					)
				}
			}
		}
	}

	init(node: NodeInfoEntity) {
		self.node = node
	}
}
