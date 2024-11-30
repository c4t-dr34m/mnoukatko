/*
Mňoukátko - the Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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

struct WaypointCoordinate: Identifiable {
	let id: UUID
	let coordinate: CLLocationCoordinate2D?
	let waypointId: Int64
}

extension WaypointEntity {
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

	var waypointCoordinate: CLLocationCoordinate2D? {
		if let latitude, let longitude, latitudeI != 0, longitudeI != 0 {
			return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		}
		else {
			return nil
		}
	}

	var annotaton: MKPointAnnotation {
		let pointAnn = MKPointAnnotation()
		if let waypointCoordinate {
			pointAnn.coordinate = waypointCoordinate
		}

		return pointAnn
	}

	static func allWaypointssFetchRequest() -> NSFetchRequest<WaypointEntity> {
		let request: NSFetchRequest<WaypointEntity> = WaypointEntity.fetchRequest()
		request.fetchLimit = 50
		request.returnsDistinctResults = true
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
		request.predicate = NSPredicate(format: "expire == nil || expire >= %@", Date() as NSDate)

		return request
	}
}

extension WaypointEntity: MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		waypointCoordinate ?? LocationManager.defaultLocation.coordinate
	}

	public var title: String? { name ?? "Dropped Pin" }

	public var subtitle: String? {
		(longDescription ?? "") +
		String(expire != nil ? "\n⌛ Expires \(String(describing: expire?.formatted()))" : "") +
		String(locked > 0 ? "\n🔒 Locked" : "")
	}
}
