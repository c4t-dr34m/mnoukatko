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
import CoreData
import CoreLocation
import MapKit
import MeshtasticProtobufs

extension PositionEntity {
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

	var nodeCoordinate: CLLocationCoordinate2D? {
		if let latitude, let longitude, latitudeI != 0, longitudeI != 0 {
			return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		}

		return nil
	}

	var nodeLocation: CLLocation? {
		if let latitude, let longitude, latitudeI != 0, longitudeI != 0 {
			return CLLocation(latitude: latitude, longitude: longitude)
		}

		return nil
	}

	var annotaton: MKPointAnnotation {
		let annotation = MKPointAnnotation()
		if let nodeCoordinate {
			annotation.coordinate = nodeCoordinate
		}

		return annotation
	}

	static func allPositionsFetchRequest() -> NSFetchRequest<PositionEntity> {
		let positionPredicate = NSPredicate(
			format: "nodePosition != nil && (nodePosition.user.shortName != nil || nodePosition.user.shortName != '') && latest == true"
		)

		let request: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
		request.predicate = positionPredicate
		request.fetchLimit = 1800
		request.returnsObjectsAsFaults = false
		request.includesSubentities = true
		request.returnsDistinctResults = true
		request.sortDescriptors = [
			NSSortDescriptor(key: "time", ascending: false)
		]

		return request
	}
}

extension PositionEntity: MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		nodeCoordinate ?? LocationManager.defaultLocation.coordinate
	}

	public var title: String? {
		nodePosition?.user?.shortName ?? "Unknown node"
	}

	public var subtitle: String? {
		time?.formatted()
	}
}
