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

	private var hasPermission: Bool {
		[.authorizedWhenInUse, .authorizedAlways].contains(authorizationStatus)
	}

	override init() {
		locationManager = CLLocationManager()
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.pausesLocationUpdatesAutomatically = false
		locationManager.allowsBackgroundLocationUpdates = true
		locationManager.activityType = .other

		super.init()

		startLocationManager()
	}

	func getLocation() -> CLLocation? {
		lastKnownLocation
	}

	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		startLocationManager()
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		lastKnownLocation = locations.last

		if let coordinate = lastKnownLocation?.coordinate {
			MeshLogger.log("📍 We got new location: \(coordinate.latitude), \(coordinate.longitude)")
		}
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
		// no-op
	}

	private func startLocationManager() {
		guard hasPermission else {
			return
		}

		locationManager.delegate = self
		locationManager.requestLocation()
	}
}
