/*
Mňoukátko - a Meshtastic® client

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
import CoreLocation
import Foundation
import MapKit
import OSLog

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	static let shared = LocationManager()
	static let defaultLocation = CLLocation( // Apple Park
		latitude: 37.3346,
		longitude: -122.0090
	)

	@Published
	var lastKnownLocation: CLLocation?
	var authorizationStatus: CLAuthorizationStatus? {
		locationManager.authorizationStatus
	}

	private let locationManager: CLLocationManager
	private let distanceFormatter = MKDistanceFormatter()

	private var hasPermission: Bool {
		[
			.authorizedWhenInUse,
			.authorizedAlways
		].contains(authorizationStatus)
	}

	override init() {
		locationManager = CLLocationManager()
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		locationManager.pausesLocationUpdatesAutomatically = false
		locationManager.activityType = .other

		super.init()

		startLocationManager()
	}

	func getLocation() -> CLLocation? {
		lastKnownLocation
	}

	func getDistanceFormatted(latitude: Double?, longitude: Double?) -> String? {
		guard let latitude, let longitude else {
			return nil
		}

		return getDistanceFormatted(
			from: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		)
	}

	func getDistanceFormatted(from coordinate: CLLocationCoordinate2D?) -> String?{
		guard
			let currentCoordinate = lastKnownLocation?.coordinate,
			let placeCoordinate = coordinate
		else {
			return nil
		}

		let me = CLLocation(
			latitude: currentCoordinate.latitude,
			longitude: currentCoordinate.longitude
		)
		let place = CLLocation(
			latitude: placeCoordinate.latitude,
			longitude: placeCoordinate.longitude
		)
		let distance = place.distance(from: me)

		return distanceFormatter.string(fromDistance: Double(distance))
	}

	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		startLocationManager()
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		lastKnownLocation = locations.last
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
		// no-op
	}

	private func startLocationManager() {
		guard hasPermission else {
			return
		}

		lastKnownLocation = locationManager.location

		locationManager.delegate = self
		locationManager.startUpdatingLocation()
	}
}
