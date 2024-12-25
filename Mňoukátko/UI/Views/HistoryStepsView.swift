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

struct HistoryStepsView: View {
	var size: CGFloat
	var foregroundColor: Color

	@ViewBuilder
	var body: some View {
		HStack(spacing: 0) {
			let angle = Angle(degrees: 80)

			Image(systemName: "shoeprints.fill")
				.font(.system(size: size))
				.foregroundColor(foregroundColor)
				.rotationEffect(angle)
			Image(systemName: "shoeprints.fill")
				.font(.system(size: size * 0.9))
				.foregroundColor(foregroundColor.opacity(0.7))
				.rotationEffect(angle)
			Image(systemName: "shoeprints.fill")
				.font(.system(size: size * 0.7))
				.foregroundColor(foregroundColor.opacity(0.4))
				.rotationEffect(angle)
		}
	}
}
