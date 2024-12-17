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
import CoreData
import CoreLocation
import FirebaseAnalytics
import MapKit
import OSLog
import SwiftUI

struct MeshMap: View {
	private let node: NodeInfoEntity?
	private let heardOfDistance: Double = 250

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@Namespace
	private var mapScope
	@StateObject
	private var appState = AppState.shared
	@State
	private var mapStyle = MapStyle.standard(
		elevation: .realistic,
		emphasis: MapStyle.StandardEmphasis.muted
	)
	@State
	private var cameraPosition = MapCameraPosition.automatic
	@State
	private var cameraDistance: Double?
	@State
	private var cameraHeading: Double?
	@State
	private var showNodeHistory: Bool? = UserDefaults.mapNodeHistory
	@State
	private var selectedPosition: PositionEntity?
	@State
	private var selectedCoordinate: CLLocationCoordinate2D?
	@FetchRequest(
		fetchRequest: PositionEntity.allPositionsFetchRequest()
	)
	private var nodePositions: FetchedResults<PositionEntity>
	private var nodePositionsHeard: [NodeInfoEntity]? {
		guard let selectedCoordinate else {
			return nil
		}

		let request = NodeInfoEntity.fetchRequest()
		if let nodes = try? context.fetch(request) {
			return nodes.compactMap { node in
				let coordinate = CLLocationCoordinate2D(
					latitude: node.lastHeardAtLatitude,
					longitude: node.lastHeardAtLongitude
				)

				if coordinate.distance(from: selectedCoordinate) <= heardOfDistance {
					return node
				}

				return nil
			}
		}

		return nil
	}
	private var userPositions: [PositionEntity]? {
		connectedDevice.device?.nodeInfo?.positions?.array as? [PositionEntity]
	}

	var body: some View {
		NavigationStack {
			ZStack(alignment: .topTrailing) {
				MapReader { _ in
					var mostRecent = node?.positions?.lastObject as? PositionEntity

					Map(
						position: $cameraPosition,
						bounds: MapCameraBounds(
							minimumDistance: 250,
							maximumDistance: .infinity
						),
						scope: mapScope
					) {
						if showNodeHistory == true {
							UserHistory(
								userPositions: userPositions,
								selectedCoordinate: $selectedCoordinate
							)
						}

						UserAnnotation()

						if
							showNodeHistory == true,
							let nodePositionsHeard,
							nodePositionsHeard.count > 0
						{
							MeshMapContent(
								nodes: nodePositionsHeard,
								showAll: true,
								selectedPosition: $selectedPosition
							)
						}
						else {
							MeshMapContent(
								positions: nodePositions.compactMap { position in
									position
								},
								selectedPosition: $selectedPosition
							)
						}
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
						mostRecent = node?.positions?.lastObject as? PositionEntity

						if let mostRecent, mostRecent.coordinate.isValid {
							cameraPosition = .camera(
								MapCamera(
									centerCoordinate: mostRecent.coordinate,
									distance: cameraPosition.camera?.distance ?? 64_000,
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

				Controls(
					position: $cameraPosition,
					distance: $cameraDistance,
					heading: $cameraHeading,
					nodeHistory: $showNodeHistory
				)
			}
			.popover(item: $selectedPosition) { position in
				if let node = position.nodePosition {
					NodeDetail(
						node: node,
						isInSheet: true
					)
					.presentationDetents([.medium])
				}
			}
			.navigationTitle("Mesh")
			.navigationBarTitleDisplayMode(.large)
			.navigationBarItems(
				trailing: ConnectionInfo()
			)
		}
		.onAppear {
			Analytics.logEvent(
				AnalyticEvents.meshMap.id,
				parameters: [
					"nodes_count": nodePositions.count
				]
			)
		}
	}

	init(node: NodeInfoEntity? = nil) {
		self.node = node
	}
}
