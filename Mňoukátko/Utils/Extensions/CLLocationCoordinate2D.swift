/*
Mňoukátko - the Meshtastic® client

Copyright © 2022-2024 Garth Vander Houwen
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
import Foundation
import MapKit

extension CLLocationCoordinate2D {
	var isValid: Bool {
		-90...90 ~= latitude && -180...180 ~= longitude
	}

	func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
		let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
		let to = CLLocation(latitude: self.latitude, longitude: self.longitude)
		return from.distance(from: to)
	}
}

extension [CLLocationCoordinate2D] {
	/// Get Convex Hull For an array of CLLocationCoordinate2D positions
	/// - Returns: A smaller CLLocationCoordinate2D array containing only the points necessary to create a convex hull polygon
	func getConvexHull() -> [CLLocationCoordinate2D] {
		/// X = longitude
		/// Y = latitude
		/// 2D cross product of OA and OB vectors, i.e. z-component of their 3D cross product.
		/// Returns a positive value, if OAB makes a counter-clockwise turn,
		/// negative for clockwise turn, and zero if the points are collinear.
		func cross(p: CLLocationCoordinate2D, a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double {
			let part1 = (a.longitude - p.longitude) * (b.latitude - p.latitude)
			let part2 = (a.latitude - p.latitude) * (b.longitude - p.longitude)
			return part1 - part2
		}
		// Sort points lexicographically
		let points = self.sorted {
			$0.longitude == $1.longitude ? $0.latitude < $1.latitude : $0.longitude < $1.longitude
		}
		// Build the lower hull
		var lower: [CLLocationCoordinate2D] = []
		for p in points {
			while lower.count >= 2 && cross(p: lower[lower.count - 2], a: lower[lower.count - 1], b: p) <= 0 {
				lower.removeLast()
			}
			lower.append(p)
		}
		// Build upper hull
		var upper: [CLLocationCoordinate2D] = []
		for p in points.reversed() {
			while upper.count >= 2 && cross(p: upper[upper.count-2], a: upper[upper.count-1], b: p) <= 0 {
				upper.removeLast()
			}
			upper.append(p)
		}
		// Last point of upper list is omitted because it is repeated at the
		// beginning of the lower list.
		upper.removeLast()
		// Concatenation of the lower and upper hulls gives the convex hull.
		return (upper + lower)
	}
}
