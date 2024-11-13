import MapKit
import SwiftUI

struct MeshMapContent: MapContent {
	@StateObject
	var appState = AppState.shared
	@Binding
	var selectedPosition: PositionEntity?

	@FetchRequest(
		fetchRequest: PositionEntity.allPositionsFetchRequest(),
		animation: .easeIn
	)
	private var positions: FetchedResults<PositionEntity>

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@State
	private var scale: CGFloat = 0.5

	@MapContentBuilder
	var body: some MapContent {
		ForEach(positions, id: \.nodePosition?.num) { position in
			if
				let node = position.nodePosition,
				let nodeName = node.user?.shortName
			{
				Annotation(
					coordinate: position.coordinate,
					anchor: .center
				) {
					avatar(for: node, name: nodeName)
						.onTapGesture {
							selectedPosition = selectedPosition == position ? nil : position
						}
				} label: {

				}
				.tag(position.time)
				.annotationTitles(.automatic)
				.annotationSubtitles(.automatic)
			}
		}
	}

	@ViewBuilder
	private func avatar(for node: NodeInfoEntity, name: String) -> some View {
		if node.isOnline {
			ZStack(alignment: .top) {
				AvatarNode(
					node,
					showTemperature: true,
					size: 48
				)
				.padding(.all, 8)

				if node.hopsAway >= 0 {
					let visible = node.hopsAway == 0

					HStack(spacing: 0) {
						Spacer()
						Image(systemName: visible ? "eye.circle.fill" : "\(node.hopsAway).circle.fill")
							.font(.system(size: 20))
							.background(node.color)
							.foregroundColor(node.color.isLight() ? .black.opacity(0.5) : .white.opacity(0.5))
							.clipShape(Circle())
					}
				}
			}
			.frame(width: 64, height: 64)
		}
		else {
			HStack(alignment: .center, spacing: 4) {
				ZStack(alignment: .center) {
					RoundedRectangle(cornerRadius: 4)
						.frame(width: 12, height: 12)
						.foregroundColor(colorScheme == .dark ? .black.opacity(0.7) : .white.opacity(0.7))
					RoundedRectangle(cornerRadius: 2)
						.frame(width: 8, height: 8)
						.foregroundColor(node.color)
				}

				if let name = node.user?.longName {
					Text(name)
						.font(.system(size: 10, weight: .light, design: .rounded))
						.foregroundColor(.primary.opacity(0.7))
				}
			}
			.padding(.all, 4)
			.overlay(
				RoundedRectangle(cornerRadius: 8)
					.stroke(.gray.opacity(0.5), lineWidth: 1)
					.background(.gray.opacity(0.2))
			)
			.clipShape(
				RoundedRectangle(cornerRadius: 8)
			)
		}
	}
}
