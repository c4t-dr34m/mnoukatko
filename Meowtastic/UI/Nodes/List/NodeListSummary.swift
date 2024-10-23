import SwiftUI

struct NodeListSummary: View {
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailIconSize: CGFloat = 16
	private let debounce = Debounce<() async -> Void>(duration: .milliseconds(500)) { action in
		await action()
	}

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@State
	private var favoriteNodes = 0
	@State
	private var onlineNodes = 0
	@State
	private var offlineNodes = 0
	@State
	private var loraNodes = 0
	@State
	private var loraSingleHopNodes = 0
	@State
	private var mqttNodes = 0
	@FetchRequest(sortDescriptors: [])
	private var nodes: FetchedResults<NodeInfoEntity>

	@ViewBuilder
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text("Online: \(onlineNodes) nodes")
				.font(.system(size: 14, weight: .regular))
				.foregroundColor(colorScheme == .dark ? .white : .black)

			VStack(alignment: .leading, spacing: 4) {
				HStack(alignment: .center, spacing: 4) {
					Image(systemName: "minus")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Image(systemName: "star.circle")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Text(String(favoriteNodes))
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)
				}

				HStack(alignment: .center, spacing: 4) {
					Image(systemName: "minus")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Image(systemName: "antenna.radiowaves.left.and.right.circle")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Text(String(loraNodes))
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Spacer()
						.frame(width: 4)

					Image(systemName: "arrow.right")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Spacer()
						.frame(width: 4)

					Image(systemName: "eye.circle")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Text(String(loraSingleHopNodes))
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Spacer()
						.frame(width: 4)

					Image(systemName: "arrowshape.bounce.forward")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Text(String(loraNodes - loraSingleHopNodes))
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)
				}

				HStack(alignment: .center, spacing: 4) {
					Image(systemName: "minus")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Image(systemName: "network")
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)

					Text(String(mqttNodes))
						.font(.system(size: 14, weight: .light))
						.foregroundColor(.gray)
				}
			}

			Divider()

			Text("Offline: \(offlineNodes) nodes")
				.font(.system(size: 14, weight: .regular))
				.foregroundColor(colorScheme == .dark ? .white : .black)

			Divider()

			Text("Total: \(onlineNodes + offlineNodes) nodes")
				.font(.system(size: 14, weight: .regular))
				.foregroundColor(colorScheme == .dark ? .white : .black)
		}
		.onChange(of: nodes, initial: true) {
			debounce.emit {
				await countNodes()
			}
		}
	}

	private func countNodes() async {
		var onlineNodes = 0
		var offlineNodes = 0
		var favoriteNodes = 0
		var loraNodes = 0
		var loraSingleHopNodes = 0
		var mqttNodes = 0

		for node in nodes {
			if node.isOnline {
				onlineNodes += 1

				if node.favorite {
					favoriteNodes += 1
				}

				if node.viaMqtt {
					mqttNodes += 1
				}
				else {
					loraNodes += 1

					if node.hopsAway == 1 {
						loraSingleHopNodes += 1
					}
				}
			}
			else {
				offlineNodes += 1
			}
		}

		self.onlineNodes = onlineNodes
		self.offlineNodes = offlineNodes
		self.favoriteNodes = favoriteNodes
		self.loraNodes = loraNodes
		self.loraSingleHopNodes = loraSingleHopNodes
		self.mqttNodes = mqttNodes
	}
}
