/*
Mňoukátko - a Meshtastic® client

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
import MapKit
import OSLog
import SwiftUI

struct UserHistory: MapContent {
	struct Entry {
		let index: Int
		let coordinate: CLLocationCoordinate2D
		let bearingToNext: Double?
	}

	private let userPositions: [PositionEntity]?
	private let heardOfDistance: Double = 250
	private let minimalDelta = 150.0 // meters
	private let distanceThreshold = 1_000.0 // meters

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@FetchRequest(sortDescriptors: [])
	private var nodes: FetchedResults<NodeInfoEntity>
	@Binding
	private var selectedCoordinate: CLLocationCoordinate2D?
	private var entries: [Entry] {
		guard let positions = userPositions else {
			return []
		}

		if let selectedCoordinate {
			return [
				Entry(
					index: 0,
					coordinate: selectedCoordinate,
					bearingToNext: nil
				)
			]
		}

		var entries = [Entry]()
		var totalDistance = 0.0

		for i in 0...(positions.count - 1) {
			let prev = i > 0 ? positions[i - 1] : nil
			let current = positions[i]
			let next = i < (positions.count - 1) ? positions[i + 1] : nil

			var bearing: Double?
			if let next {
				if current.coordinate.distance(from: next.coordinate) < minimalDelta {
					continue
				}

				bearing = current.coordinate.bearing(to: next.coordinate)
			}
			if let prev {
				totalDistance += current.coordinate.distance(from: prev.coordinate)
			}

			let newEntry = Entry(
				index: i,
				coordinate: current.coordinate,
				bearingToNext: bearing
			)

			entries.append(newEntry)
		}

		if totalDistance < distanceThreshold {
			return []
		}
		else {
			return entries
		}
	}
	private var clipInternal: UnevenRoundedRectangle {
		let corners = RectangleCornerRadii(
			topLeading: 7,
			bottomLeading: 2,
			bottomTrailing: 7,
			topTrailing: 7
		)

		return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
	}
	private var clipExternal: UnevenRoundedRectangle {
		let corners = RectangleCornerRadii(
			topLeading: 8,
			bottomLeading: 3,
			bottomTrailing: 8,
			topTrailing: 8
		)

		return UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
	}

	@MapContentBuilder
	var body: some MapContent {
		ForEach(entries, id: \.index) { entry in
			if selectedCoordinate == nil {
				MapPolyline(
					coordinates: entries.map { entry in
						entry.coordinate
					}
				)
				.stroke(
					.red.lightness(delta: colorScheme == .dark ? -0.2 : +0.2).opacity(0.8),
					style: StrokeStyle(lineWidth: 1, lineJoin: .round)
				)
			}

			Annotation(
				coordinate: entry.coordinate,
				anchor: .bottomLeading
			) {
				let nodes = getLastHeardAt(coordinate: entry.coordinate)

				HStack(alignment: .center, spacing: 0) {
					if let bearing = entry.bearingToNext {
						Image(systemName: "location.north.fill")
							.font(.system(size: 8))
							.frame(width: 14, height: 14, alignment: .center)
							.foregroundColor(colorScheme == .dark ? .black : .white)
							.rotationEffect(
								Angle(degrees: bearing)
							)
					}
					else {
						Circle()
							.padding(.all, 4)
							.frame(width: 14, height: 14, alignment: .center)
							.foregroundColor(colorScheme == .dark ? .black : .white)
					}

					if !nodes.isEmpty {
						Text("\(nodes.count)")
							.font(.system(size: 10, weight: .medium))
							.foregroundColor(colorScheme == .dark ? .black : .white)
							.padding(.trailing, 4)
					}
				}
				.background(isSelected(coordinate: entry.coordinate) ? .green : .red)
				.clipShape(clipInternal)
				.padding(.all, 2)
				.background(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5))
				.clipShape(clipExternal)
				.onTapGesture {
					guard !nodes.isEmpty else {
						return
					}

					if entry.coordinate == selectedCoordinate {
						selectedCoordinate = nil
					}
					else {
						selectedCoordinate = entry.coordinate
					}
				}
			} label: {
				// no label
			}
			.annotationTitles(.hidden)
			.annotationSubtitles(.hidden)
			.mapOverlayLevel(level: .aboveRoads)
		}
	}

	init(
		userPositions: [PositionEntity]?,
		selectedCoordinate: Binding<CLLocationCoordinate2D?>
	) {
		self.userPositions = userPositions
		self._selectedCoordinate = selectedCoordinate
	}

	private func isSelected(coordinate: CLLocationCoordinate2D) -> Bool {
		guard let selectedCoordinate else {
			return false
		}

		return selectedCoordinate.distance(from: coordinate) <= heardOfDistance
	}

	private func getLastHeardAt(coordinate: CLLocationCoordinate2D) -> [PositionEntity] {
		nodes.compactMap { node in
			let nodeCoordinate = CLLocationCoordinate2D(
				latitude: node.lastHeardAtLatitude,
				longitude: node.lastHeardAtLongitude
			)

			if nodeCoordinate.distance(from: coordinate) <= (minimalDelta - 10) {
				return node.latestPosition
			}
			else {
				return nil
			}
		}
	}
}
