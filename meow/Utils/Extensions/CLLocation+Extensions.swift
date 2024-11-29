/*
Meow - the Meshtastic® client

Copyright (C) 2022-2024 Garth Vander Houwen
Copyright (C) 2024 Radovan Paška

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

extension CLLocation {
	func bearing(to dest: CLLocation) -> Double {
		let lat1 = coordinate.latitude * .pi / 180
		let lon1 = coordinate.longitude * .pi / 180
		let lat2 = dest.coordinate.latitude * .pi / 180
		let lon2 = dest.coordinate.longitude * .pi / 180

		let deltaLon = lon2 - lon1

		let y = sin(deltaLon) * cos(lat2)
		let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

		let initialBearing = atan2(y, x)
		let bearingDegrees = (initialBearing * 180 / .pi).truncatingRemainder(dividingBy: 360)

		return (bearingDegrees + 360).truncatingRemainder(dividingBy: 360)
	}
}
