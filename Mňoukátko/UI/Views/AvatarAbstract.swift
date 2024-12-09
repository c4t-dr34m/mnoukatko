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
import SwiftUI

struct AvatarAbstract: View {
	private let name: String?
	private let icon: String
	private let color: Color?
	private let size: CGFloat
	// swiftlint:disable:next large_tuple
	private let corners: (Bool, Bool, Bool, Bool)?
	private let light: UnitPoint

	private var foregroundColor: Color {
		backgroundColor.isLight ? .black : .white
	}
	private var backgroundColor: Color {
		if let color {
			return color
		}
		else {
			return .accentColor
		}
	}
	private var background: RadialGradient {
		RadialGradient(
			colors: [
				Color(
					uiColor: backgroundColor.uiColor
						.lightness(delta: +0.1)
				),
				Color(
					uiColor: backgroundColor.uiColor
						.lightness(delta: -0.1)
						.saturation(delta: +0.3)
				)
			],
			center: light,
			startRadius: size / 4,
			endRadius: size
		)
	}

	private var radii: RectangleCornerRadii {
		let radius = size / 4

		if let corners {
			return RectangleCornerRadii(
				topLeading: corners.0 ? radius : 0,
				bottomLeading: corners.1 ? radius : 0,
				bottomTrailing: corners.2 ? radius : 0,
				topTrailing: corners.3 ? radius : 0
			)
		}
		else {
			return RectangleCornerRadii(
				topLeading: radius,
				bottomLeading: radius,
				bottomTrailing: radius,
				topTrailing: radius
			)
		}
	}

	var body: some View {
		ZStack(alignment: .center) {
			if let name, !name.isEmpty {
				Text(name)
					.font(Font.custom("Iosevka-Fixed-Heavy", size: 128))
					.foregroundColor(foregroundColor)
					.lineLimit(1)
					.minimumScaleFactor(0.01)
					.padding(.vertical, size / 8)
					.padding(.horizontal, size / 14)
					.frame(width: size, height: size)
			}
			else {
				Image(systemName: icon)
					.resizable()
					.scaledToFit()
					.foregroundColor(foregroundColor)
					.padding(.vertical, size / 8)
					.padding(.horizontal, size / 14)
					.frame(width: size, height: size)
			}
		}
		.background(background)
		.clipShape(
			UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
		)
	}

	init(
		_ name: String? = nil,
		icon: String = "person.fill.questionmark",
		color: Color? = nil,
		size: CGFloat = 45,
		// swiftlint:disable:next large_tuple
		corners: (Bool, Bool, Bool, Bool)? = nil,
		light: UnitPoint = .top
	) {
		self.name = name
		self.icon = icon
		self.color = color
		self.size = size
		self.corners = corners
		self.light = light
	}
}
