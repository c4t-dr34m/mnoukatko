/*
Meow - the Meshtastic® client

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
import CoreData
import CoreLocation
import MapKit
import SwiftUI

extension TraceRouteEntity {
	var latitude: Double? {
		let d = Double(latitudeI)
		if d == 0 {
			return 0
		}

		return d / 1e7
	}

	var longitude: Double? {
		let d = Double(longitudeI)
		if d == 0 {
			return 0
		}

		return d / 1e7
	}

	var coordinate: CLLocationCoordinate2D? {
		if latitudeI != 0 && longitudeI != 0 {
			let coord = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
			return coord
		}
		else {
			return nil
		}
	}
}

extension TraceRouteHopEntity {
	var latitude: Double? {
		let d = Double(latitudeI)
		if d == 0 {
			return 0
		}

		return d / 1e7
	}

	var longitude: Double? {
		let d = Double(longitudeI)
		if d == 0 {
			return 0
		}

		return d / 1e7
	}

	var coordinate: CLLocationCoordinate2D? {
		if latitudeI != 0 && longitudeI != 0 {
			let coord = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
			return coord
		}
		else {
			return nil
		}
	}
}
