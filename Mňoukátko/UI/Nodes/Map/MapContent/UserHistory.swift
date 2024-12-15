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

	private let minimalDelta = 500.0 // meters

	@EnvironmentObject
	private var connectedDevice: CurrentDevice

	private var entries: [Entry] {
		guard let positions = connectedDevice.device?.nodeInfo?.positions?.array as? [PositionEntity] else {
			return []
		}

		var entries = [Entry]()
		for i in 0...(positions.count - 1) {
			let previous = i > 0 ? positions[i - 1] : nil
			let current = positions[i]

			// swiftlint:disable:next force_unwrapping
			if previous == nil || current.coordinate.distance(from: previous!.coordinate) > minimalDelta {
				var bearing: Double?
				if i < positions.count - 1 {
					bearing = current.coordinate.bearing(to: positions[i + 1].coordinate)
				}
				let newEntry = Entry(
					index: i,
					coordinate: current.coordinate,
					bearingToNext: bearing
				)
				entries.append(newEntry)
			}
		}

		return entries
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
				.red,
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
				}
				else {
					Image(systemName: "record.circle.fill")
						.font(.system(size: 14))
						.foregroundColor(.red)
				}
			} label: {
				// no label
			}
			.annotationTitles(.hidden)
			.annotationSubtitles(.hidden)
			.mapOverlayLevel(level: .aboveRoads)
		}
	}
}
