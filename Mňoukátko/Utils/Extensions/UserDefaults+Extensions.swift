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
import Foundation

@propertyWrapper
struct UserDefault<T: Decodable> {
	let key: UserDefaults.Keys
	let defaultValue: T

	var wrappedValue: T {
		get {
			if defaultValue as? any RawRepresentable != nil {
				guard
					let storedValue = UserDefaults.standard.object(forKey: key.rawValue),
					let jsonString = storedValue as? String != nil ? "\"\(storedValue)\"" : "\(storedValue)",
					let data = jsonString.data(using: .utf8),
					let value = try? JSONDecoder().decode(T.self, from: data)
				else {
					return defaultValue
				}

				return value
			}

			return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
		}

		set {
			UserDefaults.standard.set(
				(newValue as? any RawRepresentable)?.rawValue ?? newValue,
				forKey: key.rawValue
			)
		}
	}

	init(_ key: UserDefaults.Keys, defaultValue: T) {
		self.key = key
		self.defaultValue = defaultValue
	}
}

extension UserDefaults {
	enum Keys: String, CaseIterable {
		case onboardingDone
		case buildNumber
		case launchCount
		case askedToReviewAt
		case locationAuthSkipped
		case wantConfigNonce
		case preferredPeripheralId // deprecated
		case preferredPeripheralIdList
		case preferredPeripheralNum // deprecated
		case preferredPeripheralNumList
		case enableAdministration
		case provideLocation
		case provideLocationInterval
		case mapLayer
		case mapNodeHistory
		case enableDetectionNotifications
		case newNodeNotifications
		case lowBatteryNotifications
		case directMessageNotifications
		case channelMessageNotifications
		case channelDisplayed
		case modemPreset
		case firmwareVersion
		case powerSavingMode
		case bcgNotification
		case lastConnectionEventCount
	}

	@UserDefault(.onboardingDone, defaultValue: false)
	static var onboardingDone: Bool

	@UserDefault(.buildNumber, defaultValue: -1)
	static var buildNumber: Int

	@UserDefault(.launchCount, defaultValue: 0)
	static var launchCount: Int

	@UserDefault(.askedToReviewAt, defaultValue: Date.distantPast)
	static var askedToReviewAt: Date

	@UserDefault(.locationAuthSkipped, defaultValue: false)
	static var locationAuthSkipped: Bool

	@UserDefault(.wantConfigNonce, defaultValue: 0)
	static var wantConfigNonce: Int

	@UserDefault(.preferredPeripheralId, defaultValue: "")
	private static var preferredPeripheralId: String

	@UserDefault(.preferredPeripheralIdList, defaultValue: [])
	static var preferredPeripheralIdList: [String]
	static var preferredPeripheralIdListFirst: String {
		if let first = preferredPeripheralIdList.first {
			return first
		}
		else {
			return ""
		}
	}

	@UserDefault(.preferredPeripheralNum, defaultValue: 0)
	private static var preferredPeripheralNum: Int

	@UserDefault(.preferredPeripheralNumList, defaultValue: [])
	static var preferredPeripheralNumList: [Int]
	static var preferredPeripheralNumListFirst: Int {
		if let first = preferredPeripheralNumList.first {
			return first
		}
		else {
			return 0
		}
	}

	@UserDefault(.enableAdministration, defaultValue: false)
	static var enableAdministration: Bool

	@UserDefault(.provideLocation, defaultValue: false)
	static var provideLocation: Bool

	@UserDefault(.provideLocationInterval, defaultValue: 30)
	static var provideLocationInterval: Int

	@UserDefault(.mapLayer, defaultValue: .standard)
	static var mapLayer: MapLayer

	@UserDefault(.mapNodeHistory, defaultValue: false)
	static var mapNodeHistory: Bool

	@UserDefault(.enableDetectionNotifications, defaultValue: false)
	static var enableDetectionNotifications: Bool

	@UserDefault(.directMessageNotifications, defaultValue: true)
	static var directMessageNotifications: Bool

	@UserDefault(.channelMessageNotifications, defaultValue: true)
	static var channelMessageNotifications: Bool

	@UserDefault(.channelDisplayed, defaultValue: false)
	static var channelDisplayed: Bool

	@UserDefault(.newNodeNotifications, defaultValue: false)
	static var newNodeNotifications: Bool

	@UserDefault(.lowBatteryNotifications, defaultValue: true)
	static var lowBatteryNotifications: Bool

	@UserDefault(.modemPreset, defaultValue: 0)
	static var modemPreset: Int

	@UserDefault(.firmwareVersion, defaultValue: "0.0.0")
	static var firmwareVersion: String

	@UserDefault(.powerSavingMode, defaultValue: false)
	static var powerSavingMode: Bool

	@UserDefault(.bcgNotification, defaultValue: false)
	static var bcgNotification: Bool

	@UserDefault(.lastConnectionEventCount, defaultValue: 0)
	static var lastConnectionEventCount: Int

	static func migrate() {
		if
			!Self.preferredPeripheralId.isEmpty,
			Self.preferredPeripheralIdList.isEmpty
		{
			Self.preferredPeripheralIdList = [ Self.preferredPeripheralId ]
		}

		if
			Self.preferredPeripheralNum != 0,
			Self.preferredPeripheralNumList.isEmpty
		{
			Self.preferredPeripheralNumList = [ Self.preferredPeripheralNum ]
		}
	}

	static func disableAllNotifications() {
		Self.directMessageNotifications = false
		Self.channelMessageNotifications = false
		Self.lowBatteryNotifications = false
		Self.newNodeNotifications = false
		Self.bcgNotification = false
	}

	static func getWantConfigNonce() -> UInt32 {
		let current = UserDefaults.wantConfigNonce
		let new: Int

		if current >= UInt32.max || current < 0 {
			new = 0
		}
		else {
			new = current + 1
		}

		UserDefaults.wantConfigNonce = new
		return UInt32(new)
	}

	func reset() {
		Keys.allCases.forEach { key in
			removeObject(forKey: key.rawValue)
		}
	}
}
