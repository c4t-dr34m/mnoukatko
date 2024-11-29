/*
Meow - the Meshtastic® client

Copyright (C) 2022-2024 Garth Vander Houwen
Copyright (C) 2024 Radovan Paška

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

extension Bundle {
	public var appName: String { getInfo("CFBundleName") }
	public var displayName: String { getInfo("CFBundleDisplayName") }
	public var language: String { getInfo("CFBundleDevelopmentRegion") }
	public var identifier: String { getInfo("CFBundleIdentifier") }
	public var copyright: String { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

	public var appBuild: String { getInfo("CFBundleVersion") }
	public var appVersionLong: String { getInfo("CFBundleShortVersionString") }
	// public var appVersionShort: String { getInfo("CFBundleShortVersion") }

	fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
