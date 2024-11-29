/*
Meow - the Meshtastic® client

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
extension Int {
	func numberOfDigits() -> Int {
		if abs(self) < 10 {
			return 1
		}
		else {
			return 1 + (self/10).numberOfDigits()
		}
	}
}

extension UInt32 {
	func toHex() -> String {
		return String(format: "!%2X", self)
	}
}

extension Int64 {
	func toHex() -> String {
		return String(format: "!%2X", self)
	}
}
