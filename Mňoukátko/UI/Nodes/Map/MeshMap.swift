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
import CoreData
import CoreLocation
import FirebaseAnalytics
import MapKit
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct MeshMap: View {
	private let node: NodeInfoEntity?
	private let nodeDetail: NodeInfoEntity?

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
		emphasis: MapStyle.StandardEmphasis.muted
	)
	@State
	private var cameraPosition = MapCameraPosition.automatic
	@State
	private var cameraDistance: Double?
	@State
	private var cameraHeading: Double?
	@State
	private var showNodeHistory = UserDefaults.mapNodeHistory
	@State
	private var selectedPosition: PositionEntity?
	@State
	private var showSpiderFor: CLLocationCoordinate2D?
	@State
	private var nodePositions: [PositionEntity] = []
	private var nodeHistoryPositions: [PositionEntity]? {
		if let nodeDetail {
			return nodeDetail.positions?.array as? [PositionEntity]
		}
		else {
			return connectedDevice.device?.nodeInfo?.positions?.array as? [PositionEntity]
		}
	}
	private var isNodeDetail: Bool {
		nodeDetail != nil
	}

	var body: some View {
		NavigationStack {
			ZStack(alignment: .topTrailing) {
				MapReader { _ in
					Map(
						position: $cameraPosition,
						bounds: MapCameraBounds(
							minimumDistance: 250,
							maximumDistance: .infinity
						),
						scope: mapScope
					) {
						if showNodeHistory || isNodeDetail {
							UserHistory(
								positions: nodeHistoryPositions,
								heading: $cameraHeading,
								showVisibleNodes: !isNodeDetail,
								selectedCoordinate: $showSpiderFor
							)
						}

						ForEach(nodePositions, id: \.nodePosition?.num) { position in
							if
								let node = position.nodePosition,
								let nodeName = node.user?.shortName,
								showSpiderFor == nil || (!node.viaMqtt && node.hopsAway == 0)
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
											guard !isNodeDetail else { return }

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
						if
							let mostRecent = nodeHistoryPositions?.last,
							mostRecent.coordinate.isValid
						{
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
					allowNodeHistory: !isNodeDetail
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

	init(node: NodeInfoEntity? = nil, detail: NodeInfoEntity? = nil) {
		self.node = node
		self.nodeDetail = detail
	}

	@ViewBuilder
	private func avatar(for node: NodeInfoEntity, name: String) -> some View {
		if (node.isOnline && showSpiderFor == nil) || isNodeDetail {
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
		if let showSpiderFor, let distance = node.latestPosition?.coordinate.distance(from: showSpiderFor) {
			HStack(alignment: .center, spacing: 4) {
				let distanceFormatted = String(format: "%.0f", distance / 1000.0) + "km"

				RoundedRectangle(cornerRadius: 2)
					.frame(width: 14)
					.frame(maxHeight: .infinity)
					.foregroundColor(node.color)

				Text(distanceFormatted)
					.font(.system(size: 12, weight: .medium))
					.foregroundStyle(colorScheme == .dark ? .white : .black)
					.padding(.trailing, 4)
			}
			.background(colorScheme == .dark ? .black : .white)
			.clipShape(
				RoundedRectangle(cornerRadius: 7)
			)
			.padding(.all, 2)
			.background(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5))
			.clipShape(
				RoundedRectangle(cornerRadius: 8)
			)
		}
		else {
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

	private func loadNodePositions() {
		if showNodeHistory, showSpiderFor == nil {
			nodePositions = []

			return
		}

		if isNodeDetail {
			if let last = nodeHistoryPositions?.last  {
				nodePositions = [ last ]
			}
			else {
				nodePositions = []
			}

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
