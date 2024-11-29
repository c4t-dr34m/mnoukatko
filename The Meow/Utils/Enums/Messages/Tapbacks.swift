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

enum Tapbacks: Int, CaseIterable, Identifiable {
	case wave = 0
	case heart = 1
	case thumbsUp = 2
	case thumbsDown = 3
	case haHa = 4
	case exclamation = 5
	case question = 6
	case poop = 7

	var id: Int {
		self.rawValue
	}

	var emojiString: String {
		switch self {
		case .wave:
			return "👋"

		case .heart:
			return "❤️"

		case .thumbsUp:
			return "👍"

		case .thumbsDown:
			return "👎"

		case .haHa:
			return "🤣"

		case .exclamation:
			return "‼️"

		case .question:
			return "❓"

		case .poop:
			return "💩"
		}
	}

	var description: String {
		switch self {
		case .wave:
			return "Wave"

		case .heart:
			return "Heart"

		case .thumbsUp:
			return "Thumbs Up"

		case .thumbsDown:
			return "Thumbs Down"

		case .haHa:
			return "Ha-Ha"

		case .exclamation:
			return "!"

		case .question:
			return "?"

		case .poop:
			return "Poop"
		}
	}
}
