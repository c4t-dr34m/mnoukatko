/*
The Meow - the Meshtastic® client

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

extension TimeZone {
	var posixDescription: String {
		if let nextDate = nextDaylightSavingTimeTransition, let afterDate = nextDaylightSavingTimeTransition(after: nextDate) {
			// This timezone observes DST

			// Get the transition dates to/from standard/DST
			let stdDate: Date
			let dstDate: Date
			if isDaylightSavingTime(for: nextDate) {
				stdDate = afterDate
				dstDate = nextDate
			} else {
				stdDate = nextDate
				dstDate = afterDate
			}

			// Append the standard abbreviation
			var res = posixAbbreviation(for: stdDate)
			// Append the standard offset
			res += posixOffset(for: stdDate)
			// Append the DST abbreviation
			res += posixAbbreviation(for: dstDate)

			// Append the DST offset if it's not 1 hour different
			let diff = secondsFromGMT(for: stdDate) - secondsFromGMT(for: dstDate)
			if abs(diff) != 3600 {
				res += posixOffset(for: dstDate)
			}

			// Get month, weekday ordinal, weekday, hour, minutes, and second
			// weekday gets returned as 1-based but we need 0-based
			// The hour is based on the post-transition time but we need the pre-transition time
			var cal = Calendar(identifier: .gregorian)
			cal.timeZone = self
			let stdcomps = cal.dateComponents([.month, .weekdayOrdinal, .weekday, .hour, .minute, .second], from: stdDate)
			let dstcomps = cal.dateComponents([.month, .weekdayOrdinal, .weekday, .hour, .minute, .second], from: dstDate)

			res += String(format: ",M%d.%d.%d/%d:%02d:%02d", dstcomps.month!, dstcomps.weekdayOrdinal!, dstcomps.weekday! - 1, dstcomps.hour! - 1, dstcomps.minute!, dstcomps.second!)
			res += String(format: ",M%d.%d.%d/%d:%02d:%02d", stdcomps.month!, stdcomps.weekdayOrdinal!, stdcomps.weekday! - 1, stdcomps.hour! + 1, stdcomps.minute!, stdcomps.second!)

			return res
		} else {
			// This timezone does not observe DST
			return "\(posixAbbreviation())\(posixOffset())"
		}
	}

	private func posixAbbreviation(for date: Date = Date()) -> String {
		let abrev = abbreviation(for: date) ?? "<UNK>" // We never actually get "<UNK>" for any TimeZone identifier
		// Many abbreviations come in the form "GMT+X" or "GMT-X"
		return abrev.hasPrefix("GMT") ? "GMT" : abrev
	}

	private func posixOffset(for date: Date = Date()) -> String {
		// The POSIX offset is the opposite of the GMT offset
		let secs = 0 - secondsFromGMT(for: date)
		let h = secs / 3600
		let m = abs(secs) % 3600 / 60
		let s = abs(secs) % 60

		// Show the hour, only show the minutes and seconds if non-zero
		return "\(h)\(m == 0 && s == 0 ? "" : ":\(String(format: "%02d", m))")\(s == 0 ? "" : ":\(String(format: "%02d", s))")"
	}
}
