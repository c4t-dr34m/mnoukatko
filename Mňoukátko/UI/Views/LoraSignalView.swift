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

struct LoraSignalView: View {
	private var snr: Float
	private var rssi: Int32
	private var preset: ModemPresets
	private var withLabels: Bool

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme

	var body: some View {
		if snr != 0.0, rssi != 0 {
			let signalStrength = LoRaSignal.getSignalStrength(snr: snr, rssi: rssi, preset: preset)

			HStack {
				Image(systemName: "cellularbars")
					.font(.system(size: 14, weight: .regular, design: .rounded))
					.foregroundColor(.gray)
					.frame(width: 16)

				Gauge(
					value: Double(signalStrength?.rawValue ?? 0),
					in: 0...3
				) { }
					.gaugeStyle(.accessoryLinearCapacity)
					.tint(.gray)

				if withLabels {
					let snrFormatted = String(format: "%.0f", snr) + "dB"

					Text(snrFormatted)
						.font(.system(size: 14, weight: .regular, design: .rounded))
						.foregroundColor(.gray)
						.lineLimit(1)
						.fixedSize(horizontal: true, vertical: true)
				}
			}
		}
	}

	init(
		snr: Float,
		rssi: Int32,
		preset: ModemPresets,
		withLabels: Bool = false
	) {
		self.snr = snr
		self.rssi = rssi
		self.preset = preset
		self.withLabels = withLabels
	}
}
