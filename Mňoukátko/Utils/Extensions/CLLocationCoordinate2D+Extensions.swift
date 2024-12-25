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
import Foundation
import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable, @retroactive CustomStringConvertible {
	public var description: String {
		"\(latitude),\(longitude)"
	}

	var isValid: Bool {
		-90...90 ~= latitude && -180...180 ~= longitude
	}

	var isLikelyEmpty: Bool {
		latitude == 0 && longitude == 0.0
	}

	public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}

	func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
		let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
		let to = CLLocation(latitude: self.latitude, longitude: self.longitude)

		return from.distance(from: to)
	}

	func bearing(to coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
		let lat1 = latitude * .pi / 180
		let lon1 = longitude * .pi / 180
		let lat2 = coordinate.latitude * .pi / 180
		let lon2 = coordinate.longitude * .pi / 180

		let deltaLon = lon2 - lon1

		let y = sin(deltaLon) * cos(lat2)
		let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

		let initialBearing = atan2(y, x)
		let bearingDegrees = (initialBearing * 180 / .pi).truncatingRemainder(dividingBy: 360)

		return (bearingDegrees + 360).truncatingRemainder(dividingBy: 360)
	}
}
