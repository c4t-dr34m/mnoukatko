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

extension Date {
	func isStale(threshold: Double) -> Bool {
		timeIntervalSinceNow < -threshold
	}

	func formattedDate(format: String) -> String {
		let dateformat = DateFormatter()
		dateformat.dateFormat = format

		// swiftlint:disable:next force_unwrapping
		if self > Calendar.current.date(byAdding: .year, value: -5, to: Date())! {
			return dateformat.string(from: self)
		}
		else {
			return "Unknown"
		}
	}

	func relative() -> String {
		let absoluteFormatter = DateFormatter()
		absoluteFormatter.dateStyle = .medium
		absoluteFormatter.timeStyle = .short

		let now = Date()

		let secondsAgo = Int(now.timeIntervalSince(self))

		if secondsAgo < 90 {
			return "Just now"
		}
		else if secondsAgo < 60 * 60 {
			let minutes = secondsAgo / 60

			if minutes == 1 {
				return "\(minutes) minute ago"
			}
			else {
				return "\(minutes) minutes ago"
			}
		}
		else if secondsAgo < 24 * 60 * 60 {
			let hours = secondsAgo / 3600

			if hours == 1 {
				return "\(hours) hour ago"
			}
			else {
				return "\(hours) hours ago"
			}
		}
		else if secondsAgo < 7 * 24 * 60 * 60 {
			let days = secondsAgo / 86400

			if days == 1 {
				return "\(days) day ago"
			}
			else {
				return "\(days) days ago"
			}
		}
		else {
			return absoluteFormatter.string(from: self)
		}
	}
}
