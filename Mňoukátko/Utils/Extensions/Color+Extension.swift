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
import SwiftUI
import UIKit

extension Color {
	var uiColor: UIColor {
		UIColor(self)
	}
	var isLight: Bool {
		uiColor.isLight
	}

	static func listBackground(for scheme: ColorScheme) -> Color {
		if scheme == .dark {
			return Color(
				red: 28 / 256,
				green: 28 / 256,
				blue: 30 / 256
			)
		}
		else {
			return .white
		}
	}

	func lightness(delta: CGFloat) -> Color {
		Color(uiColor: uiColor.lightness(delta: delta))
	}
}
