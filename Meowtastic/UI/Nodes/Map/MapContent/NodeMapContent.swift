import CoreData
import MapKit
import SwiftUI

struct NodeMapContent: MapContent {
	@Namespace
	var mapScope
	@State
	var mapStyle = MapStyle.standard(elevation: .realistic)
	@State
	var mapCamera = MapCameraPosition.automatic
	@State
	var scene: MKLookAroundScene?
	@State
	var isEditingSettings = false
	@State
	var isMeshMap = false

	private let node: NodeInfoEntity?
	private let showHistory: Bool
	private let mapHistoryLimit = 60

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@AppStorage("mapLayer")
	private var selectedMapLayer: MapLayer = .standard
	@State
	private var mapHistory = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .day, value: -7, to: .now)!
	)

	private var nodeColor: Color {
		if colorScheme == .dark {
			.white
		}
		else {
			.black
		}
	}

	private var positions: [PositionEntity] {
		if let positionArray = node?.positions?.array as? [PositionEntity] {
			if positionArray.count <= mapHistoryLimit {
				return positionArray
			}
			else {
				return Array(positionArray[..<mapHistoryLimit])
			}
		}
		else {
			return []
		}
	}

	@MapContentBuilder
	var body: some MapContent {
		if !positions.isEmpty {
			nodeMap
		}
	}

	@MapContentBuilder
	var nodeMap: some MapContent {
		if showHistory {
			history
		}

		latest
	}

	@MapContentBuilder
	private var latest: some MapContent {
		let latest = positions.first(where: { position in
			position.latest
		})

		if let latest = latest {
			let precision = PositionPrecision(rawValue: Int(latest.precisionBits))
			let radius: CLLocationDistance = precision?.precisionMeters ?? 0.0

			MapCircle(center: latest.coordinate, radius: max(66.6, radius))
				.foregroundStyle(
					Color(nodeColor).opacity(0.25)
				)
				.stroke(nodeColor.opacity(0.5), lineWidth: 2)

			Annotation(
				coordinate: latest.coordinate,
				anchor: .center
			) {
				Image(systemName: "flipphone")
					.font(.system(size: 32))
					.foregroundColor(nodeColor)
			} label: {
				// nothing
			}
			.tag(latest.time)
			.annotationTitles(.automatic)
			.annotationSubtitles(.automatic)
		}
		else {
			EmptyMapContent()
		}
	}

	@MapContentBuilder
	private var history: some MapContent {
		let positionsFiltered = positions.filter { position in
			if
				let time = position.time,
				time >= mapHistory,
				!position.latest
			{
				return true
			}
			else {
				return false
			}
		}
		let coordinates = positionsFiltered.compactMap { position -> CLLocationCoordinate2D? in
			position.nodeCoordinate
		}

		let strokeMain = StrokeStyle(
			lineWidth: 2,
			lineCap: .round,
			lineJoin: .round
		)

		let strokeOutline = StrokeStyle(
			lineWidth: 5,
			lineCap: .round,
			lineJoin: .round
		)

		MapPolyline(coordinates: coordinates)
			.stroke(Color.white.opacity(0.5), style: strokeOutline)
		MapPolyline(coordinates: coordinates)
			.stroke(Color.accentColor, style: strokeMain)
	}

	init(node: NodeInfoEntity?, showHistory: Bool = true) {
		self.node = node
		self.showHistory = showHistory
	}

	private func getFlags(for position: PositionEntity) -> PositionFlags {
		let value = position.nodePosition?.metadata?.positionFlags ?? 771

		return PositionFlags(rawValue: Int(value))
	}
}
