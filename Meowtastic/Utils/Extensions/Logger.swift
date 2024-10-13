//
//  Logger.swift
//  Meshtastic
//
//  Copyright(c) Garth Vander Houwen 6/3/24.
//

import OSLog

extension Logger {
	static let app = Logger(subsystem: subsystem, category: "📱 App")
	static let admin = Logger(subsystem: subsystem, category: "🏛 Admin")
	static let data = Logger(subsystem: subsystem, category: "🗄️ Data")
	static let mesh = Logger(subsystem: subsystem, category: "🕸️ Mesh")
	static let mqtt = Logger(subsystem: subsystem, category: "📱 MQTT")
	static let radio = Logger(subsystem: subsystem, category: "📟 Radio")
	static let services = Logger(subsystem: subsystem, category: "🍏 Services")
	static let statistics = Logger(subsystem: subsystem, category: "📊 Stats")

	private static var subsystem = Bundle.main.bundleIdentifier!
}
