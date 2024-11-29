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
