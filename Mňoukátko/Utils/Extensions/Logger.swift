/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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
import OSLog

extension Logger {
	static let app = Logger(subsystem: subsystem, category: "App")
	static let location = Logger(subsystem: subsystem, category: "Location")
	static let admin = Logger(subsystem: subsystem, category: "Admin")
	static let data = Logger(subsystem: subsystem, category: "Data")
	static let mesh = Logger(subsystem: subsystem, category: "Mesh")
	static let mqtt = Logger(subsystem: subsystem, category: "MQTT")
	static let notification = Logger(subsystem: subsystem, category: "Notification")
	static let radio = Logger(subsystem: subsystem, category: "Radio")
	static let services = Logger(subsystem: subsystem, category: "Services")
	static let statistics = Logger(subsystem: subsystem, category: "Stats")

	// swiftlint:disable:next force_unwrapping
	private static var subsystem = Bundle.main.bundleIdentifier!
}
