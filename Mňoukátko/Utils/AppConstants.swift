/*
Mňoukátko - a Meshtastic® client

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

public enum AppConstants {
	static let backgroundTaskID = "mnoukatko_refresh"

	static let nodeOnlineThreshold: Double = 15 * 60 // 15 mins
	static let nodeTelemetryThreshold: Double = 45 * 60 // 45 mins

	static let appRatingThreshold: TimeInterval = 5 * 30.25 * 24 * 60 * 60 // ~5 months; apple's minimum is 4mo

	static let scheme = "mnoukatko"
}
