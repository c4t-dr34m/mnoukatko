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
import Foundation

@propertyWrapper
struct UserDefault<T: Decodable> {
	let key: UserDefaults.Keys
	let defaultValue: T

	var wrappedValue: T {
		get {
			if defaultValue as? any RawRepresentable != nil {
				guard let storedValue = UserDefaults.standard.object(forKey: key.rawValue),
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
		case locationAuthSkipped
		case wantConfigNonce
		case preferredPeripheralId
		case preferredPeripheralNum
		case enableAdministration
		case provideLocation
		case provideLocationInterval
		case mapLayer
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
		case moreColors
		case lastConnectionEventCount
	}

	@UserDefault(.onboardingDone, defaultValue: false)
	static var onboardingDone: Bool

	@UserDefault(.locationAuthSkipped, defaultValue: false)
	static var locationAuthSkipped: Bool

	@UserDefault(.wantConfigNonce, defaultValue: 0)
	static var wantConfigNonce: Int

	@UserDefault(.preferredPeripheralId, defaultValue: "")
	static var preferredPeripheralId: String

	@UserDefault(.preferredPeripheralNum, defaultValue: 0)
	static var preferredPeripheralNum: Int

	@UserDefault(.enableAdministration, defaultValue: false)
	static var enableAdministration: Bool

	@UserDefault(.provideLocation, defaultValue: false)
	static var provideLocation: Bool

	@UserDefault(.provideLocationInterval, defaultValue: 30)
	static var provideLocationInterval: Int

	@UserDefault(.mapLayer, defaultValue: .standard)
	static var mapLayer: MapLayer

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

	@UserDefault(.moreColors, defaultValue: false)
	static var moreColors: Bool

	@UserDefault(.lastConnectionEventCount, defaultValue: 0)
	static var lastConnectionEventCount: Int

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
