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
