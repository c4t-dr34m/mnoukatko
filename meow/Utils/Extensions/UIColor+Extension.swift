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

	func lighter(componentDelta: CGFloat = 0.1) -> UIColor {
		makeColor(componentDelta: componentDelta)
	}

	func darker(componentDelta: CGFloat = 0.1) -> UIColor {
		makeColor(componentDelta: -1 * componentDelta)
	}

	func isLight() -> Bool {
		guard let components = cgColor.components, components.count > 2 else {
			return false
		}

		let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000

		return brightness > 0.5
	}

	func withIncreasedSaturation(saturationIncrease: CGFloat) -> UIColor {
		let hsl = getHSL()
		let newSaturation = min(1.0, hsl.saturation + saturationIncrease)
		let saturatedColor = withSaturation(newSaturation)

		return saturatedColor
	}

	private func add(_ value: CGFloat, toComponent: CGFloat) -> CGFloat {
		max(0, min(1, toComponent + value))
	}

	private func makeColor(componentDelta: CGFloat) -> UIColor {
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

	private func getHSL() -> (hue: CGFloat, saturation: CGFloat, lightness: CGFloat) {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0

		self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

		let lightness = (2 - saturation) * brightness / 2
		let sat = lightness == 0 || lightness == 1 ? 0 : saturation * brightness / (1 - abs(2 * lightness - 1))

		return (hue, sat, lightness)
	}

	private func withSaturation(_ newSaturation: CGFloat) -> UIColor {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0

		self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

		let newColor = UIColor(hue: hue, saturation: min(newSaturation, 1.0), brightness: brightness, alpha: alpha)

		return newColor
	}
}
