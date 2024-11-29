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
import Foundation
import MeshtasticProtobufs

// Default of 0 is Client
enum DeviceRoles: Int, CaseIterable, Identifiable {
	case client = 0
	case clientMute = 1
	case clientHidden = 8
	case tracker = 5
	case lostAndFound = 9
	case sensor = 6
	case tak = 7
	case takTracker = 10
	case repeater = 4
	case router = 2
	case routerClient = 3

	var id: Int {
		self.rawValue
	}

	var name: String {
		switch self {
		case .client:
			return "Client"

		case .clientMute:
			return "Client Mute"

		case .router:
			return "Router"

		case .routerClient:
			return "Router & Client"

		case .repeater:
			return "Repeater"

		case .tracker:
			return "Tracker"

		case .sensor:
			return "Sensor"

		case .tak:
			return "TAK"

		case .takTracker:
			return "TAK Tracker"

		case .clientHidden:
			return "Client Hidden"

		case .lostAndFound:
			return "Lost and Found"
		}
	}

	var description: String {
		self.name
	}

	var systemName: String {
		switch self {
		case .client:
			return "apps.iphone"

		case .clientMute:
			return "speaker.slash"

		case .router, .routerClient:
			return "wifi.router"

		case .repeater:
			return "repeat"

		case .tracker:
			return "mappin.and.ellipse.circle"

		case .sensor:
			return "sensor"

		case .tak:
			return "shield.checkered"

		case .takTracker:
			return "dog"

		case .clientHidden:
			return "eye.slash"

		case .lostAndFound:
			return "map"
		}
	}

	func protoEnumValue() -> Config.DeviceConfig.Role {
		switch self {
		case .client:
			return Config.DeviceConfig.Role.client

		case .clientMute:
			return Config.DeviceConfig.Role.clientMute

		case .router:
			return Config.DeviceConfig.Role.router

		case .routerClient:
			return Config.DeviceConfig.Role.routerClient

		case .repeater:
			return Config.DeviceConfig.Role.repeater

		case .tracker:
			return Config.DeviceConfig.Role.tracker

		case .sensor:
			return Config.DeviceConfig.Role.sensor

		case .tak:
			return Config.DeviceConfig.Role.tak

		case .takTracker:
			return Config.DeviceConfig.Role.takTracker

		case .clientHidden:
			return Config.DeviceConfig.Role.clientHidden

		case .lostAndFound:
			return Config.DeviceConfig.Role.lostAndFound
		}
	}
}
