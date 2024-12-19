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
import CoreLocation
import MapKit
import SwiftUI

struct SimpleNodeMap: View {
	private let mapStyle = MapStyle.standard(elevation: .flat)

	@Environment(\.managedObjectContext)
	private var context
	@Namespace
	private var mapScope
	@State
	private var positions: [PositionEntity] = []
	@State
	private var position = MapCameraPosition.automatic
	private var node: NodeInfoEntity

	var body: some View {
		if node.hasPositions {
			map
		}
		else {
			EmptyView()
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
				UserAnnotation()
				NodeMapContent(node: node, showHistory: false)
			}
			.mapScope(mapScope)
			.mapStyle(mapStyle)
			.mapControlVisibility(.hidden)
			.onAppear {
				if
					let lastCoordinate = (node.positions?.lastObject as? PositionEntity)?.coordinate,
					lastCoordinate.isValid
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
