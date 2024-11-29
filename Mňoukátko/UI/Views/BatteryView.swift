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
import Charts
import SwiftUI

struct BatteryView: View {
	@ObservedObject
	var node: NodeInfoEntity

	private let withLabels: Bool
	private let minValue = 0.0
	private let maxValue = 100.00

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme

	var body: some View {
		if let telemetries = node.telemetries {
			let deviceMetrics = telemetries.filtered(
				using: NSPredicate(format: "metricsType == 0")
			)
			let mostRecent = deviceMetrics.lastObject as? TelemetryEntity
			let batteryLevel = mostRecent?.batteryLevel
			let voltage = mostRecent?.voltage

			if let voltage, let batteryLevel, voltage > 0 || batteryLevel > 0 {
				HStack {
					if batteryLevel > 100 {
						Image(systemName: "powerplug.fill")
							.font(.system(size: 14, weight: .regular, design: .rounded))
							.foregroundColor(.gray)
							.frame(width: 16)
					}
					else {
						if batteryLevel <= 10 {
							Image(systemName: "battery.0percent")
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.frame(width: 16)
						}
						else if batteryLevel <= 35 {
							Image(systemName: "battery.25percent")
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.frame(width: 16)
						}
						else if batteryLevel <= 60 {
							Image(systemName: "battery.50percent")
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.frame(width: 16)
						}
						else if batteryLevel <= 85 {
							Image(systemName: "battery.75percent")
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.frame(width: 16)
						}
						else {
							Image(systemName: "battery.100percent")
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.frame(width: 16)
						}
					}

					Gauge(
						value: min(Double(batteryLevel), 100),
						in: minValue...maxValue
					) { }
						.gaugeStyle(.accessoryLinearCapacity)
						.tint(.gray)

					if withLabels {
						if let voltage = mostRecent?.voltage, voltage > 0, voltage <= 100 {
							let voltageFormatted = String(format: "%.1f", voltage) + "V"

							Text(voltageFormatted)
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.lineLimit(1)
								.fixedSize(horizontal: true, vertical: true)
						}
						else {
							let socFormatted = String(format: "%.0f", batteryLevel) + "%"

							Text(socFormatted)
								.font(.system(size: 14, weight: .regular, design: .rounded))
								.foregroundColor(.gray)
								.fixedSize(horizontal: true, vertical: true)
								.lineLimit(1)
						}
					}
				}
			}
		}
		else {
			EmptyView()
		}
	}

	init(
		node: NodeInfoEntity,
		withLabels: Bool = false
	) {
		self.node = node
		self.withLabels = withLabels
	}
}
