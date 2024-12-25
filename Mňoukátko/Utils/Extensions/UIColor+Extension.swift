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
import Foundation
import SwiftUI
import UIKit

extension UIColor {
	static var random: UIColor {
		UIColor(
			red: .random(in: 0...1),
			green: .random(in: 0...1),
			blue: .random(in: 0...1),
			alpha: 1.0
		)
	}

	var hex: UInt32 {
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0

		getRed(&red, green: &green, blue: &blue, alpha: &alpha)

		var value: UInt32 = 0
		value += UInt32(1.0 * 255) << 24
		value += UInt32(red * 255) << 16
		value += UInt32(green * 255) << 8
		value += UInt32(blue * 255)

		return value
	}

	// swiftlint:disable:next large_tuple
	var hsl: (hue: CGFloat, saturation: CGFloat, lightness: CGFloat) {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0

		getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

		let lightness = (2 - saturation) * brightness / 2
		let sat = lightness == 0 || lightness == 1 ? 0 : saturation * brightness / (1 - abs(2 * lightness - 1))

		return (hue, sat, lightness)
	}

	var isLight: Bool {
		hsl.lightness >= 0.55
	}

	convenience init(hex: UInt32) {
		let red = CGFloat((hex & 0xFF0000) >> 16)
		let green = CGFloat((hex & 0x00FF00) >> 8)
		let blue = CGFloat((hex & 0x0000FF))

		self.init(
			red: red / 255.0,
			green: green / 255.0,
			blue: blue / 255.0,
			alpha: 1.0
		)
	}

	func lightness(delta: CGFloat) -> UIColor {
		let newHSL = (hue: hsl.hue, saturation: hsl.saturation, lightness: hsl.lightness + delta)
		let rgb = hslToRgb(hue: newHSL.hue, saturation: newHSL.saturation, lightness: newHSL.lightness)

		return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1.0)
	}

	func saturation(delta: CGFloat) -> UIColor {
		let newSaturation = min(1.0, hsl.saturation + delta)
		return with(saturation: newSaturation)
	}

	private func add(_ value: CGFloat, toComponent: CGFloat) -> CGFloat {
		max(0, min(1, toComponent + value))
	}

	private func uiColor(delta componentDelta: CGFloat) -> UIColor {
		var red: CGFloat = 0
		var blue: CGFloat = 0
		var green: CGFloat = 0
		var alpha: CGFloat = 0

		getRed(&red, green: &green, blue: &blue, alpha: &alpha)

		return UIColor(
			red: add(componentDelta, toComponent: red),
			green: add(componentDelta, toComponent: green),
			blue: add(componentDelta, toComponent: blue),
			alpha: alpha
		)
	}

	private func with(saturation: CGFloat) -> UIColor {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0

		self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

		let newColor = UIColor(hue: hue, saturation: min(saturation, 1.0), brightness: brightness, alpha: alpha)

		return newColor
	}

	private func hslToRgb(
		hue: CGFloat,
		saturation: CGFloat,
		lightness: CGFloat
	) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
		let h = hue
		let s = saturation
		let l = lightness

		let r: CGFloat
		let g: CGFloat
		let b: CGFloat

		if s == 0 {
			r = l
			g = l
			b = l
		}
		else {
			let q = l < 0.5 ? (l * (1 + s)) : (l + s - l * s)
			let p = 2 * l - q

			r = hueToRgb(p: p, q: q, t: h + 1 / 3)
			g = hueToRgb(p: p, q: q, t: h)
			b = hueToRgb(p: p, q: q, t: h - 1 / 3)
		}

		return (red: r, green: g, blue: b)
	}

	private func hueToRgb(p: CGFloat, q: CGFloat, t: CGFloat) -> CGFloat {
		var t = t

		if t < 0 {
			t += 1
		}
		if t > 1 {
			t -= 1
		}
		if t < 1 / 6 {
			return p + (q - p) * 6 * t
		}
		if t < 1 / 2 {
			return q
		}
		if t < 2 / 3 {
			return p + (q - p) * (2 / 3 - t) * 6
		}

		return p
	}
}
