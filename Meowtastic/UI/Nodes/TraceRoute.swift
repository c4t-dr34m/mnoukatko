import FirebaseAnalytics
import MapKit
import SwiftUI

struct TraceRoute: View {
	private let coreDataTools = CoreDataTools()
	private let distanceFormatter = MKDistanceFormatter()
	private let dateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short

		return formatter
	}()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleActions: BLEActions
	@ObservedObject
	private var node: NodeInfoEntity
	@Namespace
	private var mapScope
	@State
	private var isPresentingClearLogConfirm: Bool = false
	@State
	private var selectedRoute: TraceRouteEntity?
	@State
	private var mapStyle = MapStyle.standard(
		elevation: .realistic,
		emphasis: MapStyle.StandardEmphasis.muted
	)
	@State
	private var position = MapCameraPosition.automatic

	private var nodeNum: Int64? {
		node.user?.num
	}
	private var routes: [TraceRouteEntity]? {
		guard let routes = node.traceRoutes else {
			return nil
		}

		return routes.reversed() as? [TraceRouteEntity]
	}

	@ViewBuilder
	var body: some View {
		VStack(alignment: .center) {
			if let routes {
				routeList(for: routes)
			}

			if let selectedRoute {
				if selectedRoute.response {
					routeDetail(for: selectedRoute)
				}
				else {
					routeAwaiting(for: selectedRoute)
				}
			}
			else {
				ContentUnavailableView("No Trace Route Selected", systemImage: "signpost.right.and.left")
			}
		}
		.navigationTitle("Trace Route")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.traceRoute.id, parameters: nil)
		}
	}

	init(node: NodeInfoEntity) {
		self.node = node
	}

	@ViewBuilder
	private func traceRoute(for route: TraceRouteEntity) -> some View {
		let hops = route.hops?.array as? [TraceRouteHopEntity]
		let hopCount = hops?.count

		Label {
			VStack(alignment: .leading, spacing: 4) {
				if route.response {
					if let hops, let hopCount {
						if hopCount == 0 {
							Text("Direct")
								.font(.body)
						}
						else {
							if hopCount == 1 {
								Text("\(hopCount) hop")
									.font(.body)
							}
							else {
								Text("\(hopCount) hops")
									.font(.body)
							}

							Spacer()
								.frame(height: 4)

							ForEach(hops, id: \.num) { hop in
								HStack(alignment: .center, spacing: 4) {
									let node = coreDataTools.getNodeInfo(id: hop.num, context: context)

									if let node, node.viaMqtt {
										Image(systemName: "network")
											.font(.system(size: 10))
											.foregroundColor(.gray)
											.frame(width: 24)
									}
									else {
										Image(systemName: "hare")
											.font(.system(size: 10))
											.foregroundColor(.gray)
											.frame(width: 24)
									}

									HStack(alignment: .center, spacing: 4) {
										Text(node?.user?.longName ?? "Unknown node")
											.font(.system(size: 10))
											.foregroundColor(.gray)

										if let hopTime = hop.time {
											Text(hopTime.relative())
												.font(.system(size: 10))
												.foregroundColor(.gray)
										}
									}
								}
							}

							if let destination = node.user?.longName {
								HStack(alignment: .center, spacing: 4) {
									Image(systemName: "target")
										.font(.system(size: 10))
										.foregroundColor(.gray)
										.frame(width: 24)

									Text(destination)
										.font(.system(size: 10))
										.foregroundColor(.gray)
								}
							}
						}
					}
					else {
						Text("N/A")
							.font(.body)
					}
				}
				else {
					Text("No Response")
						.font(.body)
				}

				if let time = route.time {
					HStack(spacing: 4) {
						Spacer()

						Text(dateFormatter.string(from: time))
							.font(.system(size: 10))
							.foregroundColor(.gray)
					}
				}
			}
		} icon: {
			if route.response {
				if let hopCount {
					if hopCount == 0 {
						routeIcon(name: "person.line.dotted.person.fill")
					}
					else {
						routeIcon(name: "person.2.wave.2.fill")
					}
				}
				else {
					routeIcon(name: "person.fill.questionmark")
				}
			}
			else {
				routeIcon(name: "person.slash.fill")
			}
		}
	}

	@ViewBuilder
	private func routeList(for routes: [TraceRouteEntity]) -> some View {
		List {
			if let nodeNum {
				Button {
					bleActions.sendTraceRouteRequest(
						destNum: nodeNum,
						wantResponse: true
					)
				} label: {
					Label {
						Text("Request new")
					} icon: {
						Image(systemName: "arrow.clockwise")
							.symbolRenderingMode(.monochrome)
							.foregroundColor(.accentColor)
					}
				}
			}

			ForEach(routes, id: \.num) { route in
				traceRoute(for: route)
					.onTapGesture {
						selectedRoute = route
					}
			}
		}
		.listStyle(.automatic)
		.onAppear {
			selectedRoute = routes.first
		}
	}

	@ViewBuilder
	private func routeAwaiting(for route: TraceRouteEntity) -> some View {
		VStack(alignment: .leading) {
			Spacer()

			HStack(alignment: .center, spacing: 8) {
				Image(systemName: "hourglass.circle")
					.font(.system(size: 32))

				if let longName = route.node?.user?.longName {
					VStack(alignment: .leading, spacing: 8) {
						Text("Request sent to")
							.font(.body)

						Text(longName)
							.font(.body)
					}
				}
				else {
					Text("Request sent")
						.font(.body)
				}
			}

			Spacer()
		}
	}

	@ViewBuilder
	private func routeDetail(for route: TraceRouteEntity) -> some View {
		if route.hasPositions {
			Map(
				position: $position,
				bounds: MapCameraBounds(
					minimumDistance: 100,
					maximumDistance: .infinity
				),
				scope: mapScope
			) {
				Annotation(
					"You",
					coordinate: route.coordinate ?? LocationManager.defaultLocation.coordinate
				) {
					Circle()
						.fill(Color(.green))
						.strokeBorder(.white, lineWidth: 3)
						.frame(width: 15, height: 15)
				}
				.annotationTitles(.automatic)

				// Direct Trace Route
				if
					let mostRecent = route.node?.positions?.lastObject as? PositionEntity,
					let hops = route.hops?.count,
					hops == 0
				{
					let traceRouteCoords = [
						route.coordinate ?? LocationManager.defaultLocation.coordinate,
						mostRecent.coordinate
					]
					let dashed = StrokeStyle(
						lineWidth: 2,
						lineCap: .round,
						lineJoin: .round,
						dash: [7, 10]
					)

					Annotation(
						route.node?.user?.shortName ?? "???",
						coordinate: mostRecent.nodeCoordinate ?? LocationManager.defaultLocation.coordinate
					) {
						Circle()
							.fill(Color(.black))
							.strokeBorder(.white, lineWidth: 3)
							.frame(width: 15, height: 15)
					}

					MapPolyline(coordinates: traceRouteCoords)
						.stroke(.blue, style: dashed)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}

		if
			let lastPosition = route.node?.positions?.lastObject as? PositionEntity,
			let currentCoordinate = route.coordinate,
			let lastCoordinateLatitude = lastPosition.latitude,
			let lastCoordinateLongitude = lastPosition.longitude
		{
			let distance = currentCoordinate.distance(
				from: CLLocationCoordinate2D(
					latitude: lastCoordinateLatitude,
					longitude: lastCoordinateLongitude
				)
			)
			let distanceFormatted = distanceFormatter.string(fromDistance: Double(distance))

			Label {
				Text("Distance: \(distanceFormatted)")
					.foregroundColor(.primary)
			} icon: {
				Image(systemName: "lines.measurement.horizontal")
					.symbolRenderingMode(.hierarchical)
			}
		}
	}

	@ViewBuilder
	private func routeIcon(name: String) -> some View {
		Image(systemName: name)
			.resizable()
			.scaledToFit()
			.frame(width: 32, height: 32)
	}
}
