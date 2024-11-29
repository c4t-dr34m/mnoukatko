import Foundation
import SwiftUI

struct MQTTChannelIcon: View {
	var connected = false
	var uplink = false
	var downlink = false

	private var icon: String {
		if uplink && downlink {
			return "arrow.up.arrow.down.circle.fill"
		}
		else if uplink {
			return "arrow.up.circle.fill"
		}
		else if downlink {
			return "arrow.down.circle.fill"
		}
		else {
			return "slash.circle"
		}
	}

	private var color: Color {
		connected ? .green : .gray
	}

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
