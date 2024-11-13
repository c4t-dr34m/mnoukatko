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
