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

	@Environment(\.managedObjectContext)
	private var context
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
	private var selectedPosition: PositionEntity?
	@State
	private var visibleAnnotations = 0
	@State
	private var showLabelsForOffline = false
	@FetchRequest(
		fetchRequest: PositionEntity.allPositionsFetchRequest()
	)
	private var positions: FetchedResults<PositionEntity>

	var body: some View {
		NavigationStack {
			ZStack {
				var mostRecent = node?.positions?.lastObject as? PositionEntity

				MapReader { _ in
					Map(
						position: $cameraPosition,
						bounds: MapCameraBounds(
							minimumDistance: 250,
							maximumDistance: .infinity
						),
						scope: mapScope
					) {
						UserHistory()
						UserAnnotation()
						MeshMapContent(
							selectedPosition: $selectedPosition,
							showLabelsForOffline: $showLabelsForOffline,
							onAppear: { _ in
								visibleAnnotations += 1
							},
							onDisappear: { _ in
								visibleAnnotations -= 1
							}
						)
					}
					.mapScope(mapScope)
					.mapStyle(mapStyle)
					.mapControls {
						MapScaleView(scope: mapScope)
							.mapControlVisibility(.visible)

						MapUserLocationButton(scope: mapScope)
							.mapControlVisibility(.visible)

						MapPitchToggle(scope: mapScope)
							.mapControlVisibility(.automatic)

						MapCompass(scope: mapScope)
							.mapControlVisibility(.automatic)
					}
					.controlSize(.regular)
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
					.onChange(of: visibleAnnotations, initial: true) {
						showLabelsForOffline = visibleAnnotations < 100 && positions.count > 100
					}
				}
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
					"nodes_count": positions.count
				]
			)
		}
	}

	init(node: NodeInfoEntity? = nil) {
		self.node = node
	}
}
