import CoreData
import CoreLocation
import FirebaseAnalytics
import MapKit
import OSLog
import SwiftUI

struct MeshMap: View {
	@Environment(\.managedObjectContext)
	private var context
	@StateObject
	private var appState = AppState.shared
	@Namespace
	private var mapScope
	@State
	private var mapStyle = MapStyle.standard(
		elevation: .realistic,
		emphasis: MapStyle.StandardEmphasis.muted
	)
	@State
	private var position = MapCameraPosition.automatic
	@State
	private var selectedPosition: PositionEntity?

	private let node: NodeInfoEntity?

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
						position: $position,
						bounds: MapCameraBounds(
							minimumDistance: 250,
							maximumDistance: .infinity
						),
						scope: mapScope
					) {
						UserAnnotation()
						MeshMapContent(
							selectedPosition: $selectedPosition
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
							position = .camera(
								MapCamera(
									centerCoordinate: mostRecent.coordinate,
									distance: position.camera?.distance ?? 64_000,
									heading: 0,
									pitch: 40
								)
							)
						}
						else {
							position = .automatic
						}
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
					"nodes_count": positions
				]
			)
		}
	}

	init(node: NodeInfoEntity? = nil) {
		self.node = node
	}
}
