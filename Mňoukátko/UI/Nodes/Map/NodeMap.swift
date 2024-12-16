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
import FirebaseAnalytics
import MapKit
import SwiftUI

struct NodeMap: View {
	@Environment(\.managedObjectContext)
	private var context

	@AppStorage("mapLayer")
	private var selectedMapLayer: MapLayer = .standard
	@Namespace
	private var mapScope
	@State
	private var positions: [PositionEntity] = []
	@State
	private var cameraPosition = MapCameraPosition.automatic
	@State
	private var cameraDistance: Double?
	@State
	private var cameraHeading: Double?
	@State
	private var isMeshMap = false
	@State
	private var mapRegion = MKCoordinateRegion()

	private let node: NodeInfoEntity
	private var screenTitle: String {
		if let name = node.user?.shortName {
			return name
		}
		else {
			return "Node Map"
		}
	}
	private var mapStyle: MapStyle {
		getMapStyle(for: selectedMapLayer)
	}
	private var positionCount: Int {
		node.positions?.count ?? 0
	}

	var body: some View {
		if node.hasPositions {
			map
				.navigationBarTitle(
					screenTitle,
					displayMode: .inline
				)
				.navigationBarItems(
					trailing: ConnectionInfo()
				)
				.onAppear {
					Analytics.logEvent(
						AnalyticEvents.nodeMap.id,
						parameters: AnalyticEvents.getParams(for: node)
					)
				}
		}
		else {
			ContentUnavailableView("No Positions", systemImage: "mappin.slash")
		}
	}

	@ViewBuilder
	private var map: some View {
		var mostRecent = node.positions?.lastObject as? PositionEntity

		ZStack(alignment: .topTrailing) {
			MapReader { _ in
				Map(
					position: $cameraPosition,
					bounds: MapCameraBounds(minimumDistance: 100, maximumDistance: .infinity),
					scope: mapScope
				) {
					UserAnnotation()
					NodeMapContent(node: node)
				}
				.mapScope(mapScope)
				.mapStyle(mapStyle)
				.mapControls {
					MapCompass(scope: mapScope).mapControlVisibility(.hidden)
					MapPitchToggle(scope: mapScope).mapControlVisibility(.hidden)
				}
				.onMapCameraChange(frequency: .continuous) { map in
					cameraDistance = map.camera.distance
					cameraHeading = map.camera.heading
				}
				.onChange(of: node, initial: true) {
					mostRecent = node.positions?.lastObject as? PositionEntity

					if let mostRecent, mostRecent.coordinate.isValid {
						cameraPosition = .camera(
							MapCamera(
								centerCoordinate: mostRecent.coordinate,
								distance: 8000,
								heading: 0,
								pitch: 40
							)
						)
					}
					else {
						cameraPosition = .automatic
					}
				}
			}

			Controls(position: $cameraPosition, distance: $cameraDistance, heading: $cameraHeading)
		}
	}

	init(node: NodeInfoEntity) {
		self.node = node
	}

	private func getMapStyle(for layer: MapLayer) -> MapStyle {
		switch layer {
		case .standard:
			return MapStyle.standard(
				elevation: .flat
			)

		case .hybrid, .offline:
			return MapStyle.hybrid(
				elevation: .flat
			)

		case .satellite:
			return MapStyle.imagery(
				elevation: .flat
			)
		}
	}
}
