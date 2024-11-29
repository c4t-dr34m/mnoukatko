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
						showLabelsForOffline = visibleAnnotations < 100
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
