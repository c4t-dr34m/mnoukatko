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
import UIKit

extension String {
	var localized: String {
		NSLocalizedString(self, comment: self)
	}

	func isEmoji() -> Bool {
		// Emoji are no more than 4 bytes
		if self.count > 4 {
			return false
		}
		else {
			let characters = Array(self)
			if characters.count <= 0 {
				return false
			}
			else {
				return characters[0].isEmoji
			}
		}
	}

	func camelCaseToWords() -> String {
		unicodeScalars
			.dropFirst()
			.reduce(String(prefix(1))) {
				CharacterSet.uppercaseLetters.contains($1)
				? $0 + " " + String($1)
				: $0 + String($1)
			}
	}

	subscript (i: Int) -> String {
		self[i ..< i + 1]
	}

	subscript (r: Range<Int>) -> String {
		let range = Range(
			uncheckedBounds: (
				lower: max(0, min(count, r.lowerBound)),
				upper: min(count, max(0, r.upperBound))
			)
		)
		let start = index(startIndex, offsetBy: range.lowerBound)
		let end = index(start, offsetBy: range.upperBound - range.lowerBound)

		return String(self[start ..< end])
	}
}
