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
	private var connectedDevice: CurrentDevice
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
					// TODO: show map if it makes any sense
					// routeDetail(for: selectedRoute)
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

	@ViewBuilder
	private var routeStart: some View {
		if let myName = connectedDevice.device?.longName {
			HStack(alignment: .center, spacing: 4) {
				Image(systemName: "flipphone")
					.font(.system(size: 14))
					.foregroundColor(.primary)
					.frame(width: 24)

				Text(myName)
					.font(.system(size: 14))
					.foregroundColor(.primary)
			}
		}
	}

	@ViewBuilder
	private var routeFinish: some View {
		if let destination = node.user?.longName {
			Divider()

			HStack(alignment: .center, spacing: 4) {
				Image(systemName: "flag.pattern.checkered.2.crossed")
					.font(.system(size: 14))
					.foregroundColor(.primary)
					.frame(width: 24)

				Text(destination)
					.font(.system(size: 14))
					.foregroundColor(.primary)
			}
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

							routeStart
							hopList(for: hops)
							routeFinish
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
			routeIcon(hasResponse: route.response, hopCount: hopCount)
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
							.foregroundColor(.primary)
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
							.foregroundColor(.primary)

						Text(longName)
							.font(.body)
							.foregroundColor(.primary)
					}
				}
				else {
					Text("Request sent")
						.font(.body)
						.foregroundColor(.primary)
				}
			}

			Spacer()
		}
	}

	@ViewBuilder
	private func hopList(for hops: [TraceRouteHopEntity]) -> some View {
		ForEach(hops, id: \.num) { hop in
			VStack(alignment: .leading, spacing: 4) {
				Divider()

				HStack(alignment: .center, spacing: 4) {
					let node = coreDataTools.getNodeInfo(id: hop.num, context: context)

					if let node, node.viaMqtt {
						Image(systemName: "network")
							.font(.system(size: 14))
							.foregroundColor(.primary)
							.frame(width: 24)
					}
					else {
						Image(systemName: "hare")
							.font(.system(size: 14))
							.foregroundColor(.primary)
							.frame(width: 24)
					}

					VStack(alignment: .leading, spacing: 8) {
						Text(node?.user?.longName ?? "Unknown node")
							.font(.system(size: 14))
							.foregroundColor(.primary)

						if let hopTime = hop.time {
							HStack(spacing: 4) {
								Text(hopTime.relative())
									.font(.system(size: 10))
									.foregroundColor(.gray)

								if hop.latitudeI != 0, hop.longitudeI != 0 {
									Image(systemName: "globe.europe.africa.fill")
										.font(.system(size: 10))
										.foregroundColor(.gray)
								}
							}
						}
					}
				}
			}
		}
	}

	@ViewBuilder
	private func routeIcon(hasResponse: Bool, hopCount: Int?) -> some View {
		if hasResponse {
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

	@ViewBuilder
	private func routeIcon(name: String) -> some View {
		Image(systemName: name)
			.resizable()
			.scaledToFit()
			.frame(width: 32, height: 32)
			.foregroundStyle(Color.accentColor)
	}
}
