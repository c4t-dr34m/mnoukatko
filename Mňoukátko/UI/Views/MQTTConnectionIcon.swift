/*
Mňoukátko - the Meshtastic® client

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

struct MQTTConnectionIcon: View {
	var connected = false

	private var icon: String {
		if connected {
			return "network"
		}
		else {
			return "network.slash"
		}
	}

	private var color: Color {
		connected ? .green : .gray
	}

	@ViewBuilder
	var body: some View {
		Image(systemName: icon)
			.resizable()
			.scaledToFit()
			.frame(width: 16, height: 16)
			.foregroundColor(color)
			.padding(.vertical, 8)
			.padding(.leading, 8)
			.padding(.trailing, 12)
			.background(color.opacity(0.3))
	}
}
