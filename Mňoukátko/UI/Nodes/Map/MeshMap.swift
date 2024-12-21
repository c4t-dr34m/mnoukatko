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

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
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
		elevation: .flat,
		emphasis: MapStyle.StandardEmphasis.automatic
	)
	@State
	private var cameraPosition = MapCameraPosition.automatic
	@State
	private var cameraDistance: Double?
	@State
	private var cameraHeading: Double?
	@State
	private var nodePositions: [PositionEntity] = []
	@State
	private var showNodeHistory = UserDefaults.mapNodeHistory
	@State
	private var selectedPosition: PositionEntity?
	@State
	private var showSpiderFor: CLLocationCoordinate2D?
	private var userPositions: [PositionEntity]? {
		guard showNodeHistory else {
			return nil
		}

		return connectedDevice.device?.nodeInfo?.positions?.array as? [PositionEntity]
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
						if showNodeHistory {
							UserHistory(
								userPositions: userPositions,
								selectedCoordinate: $showSpiderFor
							)
						}

						ForEach(nodePositions, id: \.nodePosition?.num) { position in
							if
								let node = position.nodePosition,
								let nodeName = node.user?.shortName,
								!node.viaMqtt,
								node.hopsAway == 0
							{
								if
									let showSpiderFor,
									showSpiderFor.distance(from: node.lastHeardAt) < MapConstants.heardOfRadius
								{
									MapPolyline(
										coordinates: [ showSpiderFor, position.coordinate ]
									)
									.stroke(
										.gray,
										style: StrokeStyle(lineWidth: 1, lineJoin: .round)
									)
									.tag("\(nodeName)_spider")
								}

								Annotation(
									coordinate: position.coordinate,
									anchor: .center
								) {
									avatar(for: node, name: nodeName)
										.onTapGesture {
											selectedPosition = selectedPosition == position ? nil : position
										}
								} label: {
									// no label
								}
								.tag("\(nodeName)_annotation")
								.mapOverlayLevel(level: node.isOnline ? .aboveLabels : .aboveRoads)
							}
						}

						UserAnnotation()
					}
					.mapScope(mapScope)
					.mapStyle(mapStyle)
					.mapControlVisibility(.hidden)
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
									distance: cameraPosition.camera?.distance ?? 16_000,
									heading: 0
								)
							)
						}
						else {
							cameraPosition = .automatic
						}
					}
					.onChange(of: showSpiderFor, initial: true) {
						loadNodePositions()
					}
					.onChange(of: showNodeHistory) {
						showSpiderFor = nil
						loadNodePositions()
					}
				}

				Controls(
					position: $cameraPosition,
					distance: $cameraDistance,
					heading: $cameraHeading,
					nodeHistory: $showNodeHistory,
					allowNodeHistory: true
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

	@ViewBuilder
	private func avatar(for node: NodeInfoEntity, name: String) -> some View {
		if node.isOnline, showSpiderFor == nil {
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
			offlineNodeDot(for: node)
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

	private func loadNodePositions() {
		if showNodeHistory, showSpiderFor == nil {
			nodePositions = []

			return
		}

		let request = PositionEntity.fetchRequest()
		request.predicate = NSPredicate(
			format: "nodePosition != nil && nodePosition.user.shortName != nil && nodePosition.user.shortName != '' && latest == true"
		)
		request.includesSubentities = true
		request.returnsDistinctResults = true

		if let positions = try? context.fetch(request) {
			nodePositions = positions.compactMap { position in
				guard let showSpiderFor else {
					return position
				}

				if
					let lastHeardAt = position.nodePosition?.lastHeardAt,
					showSpiderFor.distance(from: lastHeardAt) < MapConstants.heardOfRadius
				{
					return position
				}
				else {
					return nil
				}
			}
		}
		else {
			nodePositions = []
		}
	}
}
