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
	private let minimalDelta = 150.0 // meters
	private let distanceThreshold = 1_000.0 // meters

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	private var entries: [Entry] {
		guard let positions = userPositions else {
			return []
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

	@MapContentBuilder
	var body: some MapContent {
		ForEach(entries, id: \.index) { entry in
			MapPolyline(
				coordinates: entries.map { entry in
					entry.coordinate
				},
				contourStyle: .geodesic
			)
			.stroke(
				.red.lightness(delta: colorScheme == .dark ? -0.2 : +0.2).opacity(0.8),
				style: StrokeStyle(lineWidth: 1, lineJoin: .round)
			)

			Annotation(
				coordinate: entry.coordinate,
				anchor: .center
			) {
				if let bearing = entry.bearingToNext {
					Image(systemName: "location.north.circle.fill")
						.font(.system(size: 14))
						.foregroundColor(.red)
						.rotationEffect(
							Angle(degrees: bearing)
						)
						.background(colorScheme == .dark ? .black : .white)
						.clipShape(Circle())
						.padding(.all, 2)
						.background(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5))
						.clipShape(Circle())
				}
				else {
					Image(systemName: "record.circle.fill")
						.font(.system(size: 14))
						.foregroundColor(.red)
						.background(colorScheme == .dark ? .black : .white)
						.clipShape(Circle())
						.padding(.all, 2)
						.background(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5))
						.clipShape(Circle())
				}
			} label: {
				// no label
			}
			.annotationTitles(.hidden)
			.annotationSubtitles(.hidden)
			.mapOverlayLevel(level: .aboveRoads)
		}
	}

	init(userPositions: [PositionEntity]?) {
		self.userPositions = userPositions
	}
}
