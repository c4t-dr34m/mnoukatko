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

final class LoRaSignal {
	static func getSignalStrength(snr: Float, rssi: Int32, preset: ModemPresets) -> SignalStrength? {
		guard snr != 0, rssi != 0 else {
			return nil
		}

		if rssi > -115 && snr > preset.snrLimit() {
			return .strong
		}
		else if rssi < -126 && snr < preset.snrLimit() - 7.5 {
			return nil
		}
		else if rssi <= -120 || snr <= preset.snrLimit() - 5.5 {
			return .weak
		}
		else {
			return .normal
		}
	}

	static func getRssiColor(rssi: Int32) -> Color {
		if rssi > -115 {
			return .green
		}
		else if rssi > -120 {
			return .yellow
		}
		else if rssi > -126 {
			return .orange
		}
		else {
			return .red
		}
	}

	static func getSnrColor(snr: Float, preset: ModemPresets) -> Color {
		if snr > preset.snrLimit() {
			return .green
		}
		else if snr < preset.snrLimit() && snr > (preset.snrLimit() - 5.5) {
			return .yellow
		}
		else if snr >= (preset.snrLimit() - 7.5) {
			return .orange
		}
		else {
			return .red
		}
	}
}
