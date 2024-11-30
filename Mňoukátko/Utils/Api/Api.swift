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
import Foundation
import OSLog

final class Api: ObservableObject {
	func loadDeviceHardwareData(completion: @escaping ([DeviceHardware]) -> Void) {
		// List from https://api.meshtastic.org/resource/deviceHardware
		guard let url = Bundle.main.url(
			forResource: "DeviceHardware.json",
			withExtension: nil
		) else {
			Logger.services.critical("Couldn't find DeviceHardware.json in main bundle.")

			return
		}

		URLSession.shared.dataTask(with: url) { data, _, _ in
			if
				let data,
				let hardware = try? JSONDecoder().decode([DeviceHardware].self, from: data)
			{
				DispatchQueue.main.async {
					completion(hardware)
				}
			}
		}
		.resume()
	}

	func loadFirmwareReleaseData(completion: @escaping (FirmwareReleases) -> Void) {
		guard let url = URL(string: "https://api.meshtastic.org/github/firmware/list") else {
			Logger.services.error("Invalid url...")

			return
		}

		URLSession.shared.dataTask(with: url) { data, _, _ in
			if
				let data,
				let firmware = try? JSONDecoder().decode(FirmwareReleases.self, from: data)
			{
				DispatchQueue.main.async {
					completion(firmware)
				}
			}
		}
		.resume()
	}
}
