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
import Charts
import CoreGraphics
import FirebaseAnalytics
import MapKit
import OSLog
import SwiftUI

// swiftlint:disable file_length
struct NodeDetail: View {
	private let coreDataTools = CoreDataTools()
	private let node: NodeInfoEntity
	private let isInSheet: Bool
	private let telemetryDelta: TimeInterval = 30 * 60 // 30 min
	private let distanceFormatter = MKDistanceFormatter()
	private let detailInfoTextFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let detailInfoIconFont = Font.system(size: 16, weight: .regular, design: .rounded)
	private let detailIconSize: CGFloat = 18
	private let statusDotSize: CGFloat = 8

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@EnvironmentObject
	private var locationManager: LocationManager

	@State
	private var showingShutdownConfirm = false
	@State
	private var showingRebootConfirm = false
	@State
	private var chartHistory = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .day, value: -5, to: .now)!
	)
	@State
	private var tomorrowMidnight = Calendar.current.startOfDay(
		// swiftlint:disable:next force_unwrapping
		for: Calendar.current.date(byAdding: .day, value: +1, to: .now)!
	)

	private var connectedNode: NodeInfoEntity? {
		guard let num = connectedDevice.device?.num else {
			return nil
		}

		return coreDataTools.getNodeInfo(id: num, context: context)
	}
	private var nodePosition: PositionEntity? {
		node.positions?.lastObject as? PositionEntity
	}
	private var nodePositionStale: Bool {
		nodePosition != nil
		&& nodePosition?.time?.isStale(threshold: AppConstants.nodeTelemetryThreshold) ?? true
		&& nodePosition?.speed ?? 0 > 0
	}
	private var nodeTelemetries: [TelemetryEntity]? {
		node.telemetries?.array as? [TelemetryEntity]
	}
	private var nodeTelemetryLast: TelemetryEntity? {
		nodeTelemetries?.last(where: { telemetry in
			telemetry.metricsType == 0
		})
	}
	private var nodeEnvironmentHistory: [TelemetryEntity]? {
		let telemetries = nodeTelemetries?.filter { telemetry in
			telemetry.metricsType == 1
		}

		guard let telemetries, !telemetries.isEmpty else {
			return nil
		}

		let historyLength = telemetries.count
		var measurements: [TelemetryEntity] = []

		for i in 0...(historyLength - 1) {
			let current = telemetries[i]
			let next = i < (historyLength - 1) ? telemetries[i + 1] : nil

			if let next {
				if
					let currentTime = current.time,
					currentTime > chartHistory,
					let nextTime = next.time,
					currentTime.distance(to: nextTime) >= telemetryDelta
				{
					measurements.append(current)
				}
			}
			else {
				measurements.append(current)
			}
		}

		return measurements
	}
	private var nodePressureHistory: [TelemetryEntity]? {
		nodeEnvironmentHistory?.filter { measurement in
			measurement.barometricPressure > 0
		}
	}
	private var nodeEnvironment: TelemetryEntity? {
		nodeEnvironmentHistory?.last
	}

	var body: some View {
		NavigationStack {
			List {
				Section {
					NodeInfoView(node: node)
				}
				.headerProminence(.increased)

				if nodePosition != nil {
					Section(
						header: Text("Location").fontDesign(.rounded)
					) {
						locationInfo
							.padding(.horizontal, 4)

						if node.hasPositions {
							if isInSheet {
								VStack {
									SimpleNodeMap(node: node)
										.frame(height: 120)
										.cornerRadius(8)
										.disabled(true)
										.toolbar(.hidden)

									locationUpdateInfo
								}
							}
							else {
								NavigationLink {
									NavigationLazyView(
										NodeMap(node: node)
									)
								} label: {
									VStack {
										SimpleNodeMap(node: node)
											.frame(height: 160)
											.cornerRadius(8)
											.disabled(true)

										locationUpdateInfo
									}
								}
							}
						}
					}
					.listRowSeparator(.hidden)
					.listRowSpacing(0)
					.headerProminence(.increased)
				}

				if nodeEnvironment != nil {
					Section(
						header: Text("Environment").fontDesign(.rounded)
					) {
						environmentInfo

						temperatureHistory
							.padding(.vertical, 8)

						pressureHistory
							.padding(.vertical, 8)
					}
					.listRowSeparator(.hidden)
					.listRowSpacing(0)
					.headerProminence(.increased)
				}

				Section(
					header: Text("Details").fontDesign(.rounded)
				) {
					nodeInfo
				}
				.headerProminence(.increased)

				if !isInSheet {
					actions

					if
						let connectedNode,
						connectedNode.num == node.num,
						let nodeMetadata = node.metadata
					{
						Section(
							header: Text("Administration").fontDesign(.rounded)
						) {
							admin(node: connectedNode, metadata: nodeMetadata)
						}
						.headerProminence(.increased)
					}
				}
			}
			.listStyle(.insetGrouped)
		}
		.onAppear {
			Analytics.logEvent(
				AnalyticEvents.nodeDetail.id,
				parameters: AnalyticEvents.getParams(for: node, [ "sheet": isInSheet ])
			)
		}
		.navigationBarItems(
			trailing: navigationBarButtons
		)
	}

	@ViewBuilder
	private var navigationBarButtons: some View {
		HStack(spacing: 4) {
			Button {
				guard let connectedNodeNum = connectedDevice.device?.num else {
					return
				}

				let success = if node.favorite {
					nodeConfig.removeFavoriteNode(
						node: node,
						connectedNodeNum: Int64(connectedNodeNum)
					)
				}
				else {
					nodeConfig.saveFavoriteNode(
						node: node,
						connectedNodeNum: Int64(connectedNodeNum)
					)
				}

				if success {
					context.refresh(node, mergeChanges: true)
					do {
						try context.save()
					}
					catch {
						context.rollback()
					}

					node.favorite.toggle()
				}
			} label: {
				Image(systemName: node.favorite ? "star.slash" : "star")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}

			if let user = node.user, let device = connectedDevice.device, node.num != device.num {
				Button {
					user.mute.toggle()
					context.refresh(node, mergeChanges: true)

					do {
						try context.save()
					}
					catch {
						context.rollback()
					}
				} label: {
					Image(systemName: user.mute ? "bell.slash" : "bell")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				NavigationLink {
					NavigationLazyView(
						MessageList(user: user, myInfo: node.myInfo)
					)
				} label: {
					Image(systemName: "bubble.left.and.bubble.right")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}
			}
		}
	}

	@ViewBuilder
	private var locationInfo: some View {
		if let position = nodePosition {
			HStack(alignment: .center, spacing: 8) {
				if
					let distance = locationManager.getDistanceFormatted(
						from: (node.positions?.lastObject as? PositionEntity)?.coordinate
					)
				{
					Image(systemName: "mappin.and.ellipse")
						.font(detailInfoIconFont)
						.foregroundColor(.primary)
						.frame(width: detailIconSize)

					Text(distance)
						.font(detailInfoTextFont)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						.foregroundColor(.primary)

					Spacer()
						.frame(width: 4)
				}

				let altitudeFormatted = distanceFormatter.string(
					fromDistance: Double(position.altitude)
				)

				Image(systemName: "mountain.2")
					.font(detailInfoIconFont)
					.foregroundColor(.primary)
					.frame(width: detailIconSize)

				Text(altitudeFormatted)
					.font(detailInfoTextFont)
					.lineLimit(1)
					.minimumScaleFactor(0.5)
					.foregroundColor(.primary)

				let precision = PositionPrecision(rawValue: Int(position.precisionBits))?.precisionMeters
				if let precision {
					let precisionFormatted = distanceFormatter.string(
						fromDistance: Double(precision)
					)

					Spacer()
						.frame(width: 4)

					Image(systemName: "scope")
						.font(detailInfoIconFont)
						.foregroundColor(.primary)
						.frame(width: detailIconSize)

					Text(precisionFormatted)
						.font(detailInfoTextFont)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						.foregroundColor(.primary)
				}
			}

			if position.speed > 0 {
				HStack(alignment: .center, spacing: 8) {
					let speed = Measurement(
						value: Double(position.speed),
						unit: UnitSpeed.kilometersPerHour
					)
					let speedFormatted = speed.formatted(
						.measurement(
							width: .abbreviated,
							numberFormatStyle: .number.precision(.fractionLength(0))
						)
					)
					let heading = Angle.degrees(
						Double(position.heading)
					)
					let headingDegrees = Measurement(
						value: heading.degrees,
						unit: UnitAngle.degrees
					)
					let headingFormatted = headingDegrees.formatted(
						.measurement(
							width: .narrow,
							numberFormatStyle: .number.precision(.fractionLength(0))
						)
					)

					Image(systemName: "gauge.open.with.lines.needle.33percent")
						.font(detailInfoIconFont)
						.foregroundColor(.primary)
						.frame(width: detailIconSize)

					Text(speedFormatted)
						.font(detailInfoTextFont)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						.foregroundColor(.primary)

					Spacer()
						.frame(width: 4)

					Image(systemName: "safari")
						.font(detailInfoIconFont)
						.foregroundColor(.primary)
						.frame(width: detailIconSize)

					Text(headingFormatted)
						.font(detailInfoTextFont)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						.foregroundColor(.primary)

					Spacer()
						.frame(width: 4)
				}
			}
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var locationUpdateInfo: some View {
		if let position = nodePosition {
			HStack(alignment: .center, spacing: 0) {
				Spacer()

				if let time = position.time, time.distance(to: Date(timeIntervalSince1970: 0)) != 0 {
					Text("Updated: \(time.relative())")
						.font(.system(size: 10, weight: .light))
						.foregroundColor(.gray)
				}
				else {
					Text("Unknown time of update")
						.font(.system(size: 10, weight: .light))
						.foregroundColor(.gray)
				}
			}
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var environmentInfo: some View {
		if let nodeEnvironment {
			let temp = nodeEnvironment.temperature
			let tempFormatted = String(format: "%.1f", temp) + "°C"
			let pressureFormatted = String(format: "%.0f", nodeEnvironment.barometricPressure.rounded()) + "hPa"
			let humidityFormatted = String(format: "%.0f", nodeEnvironment.relativeHumidity.rounded()) + "%"
			let windFormatted = String(format: "%.0f", nodeEnvironment.windSpeed.rounded()) + "m/s"

			HStack(alignment: .center, spacing: 8) {
				if nodeEnvironment.windSpeed != 0 {
					Image(systemName: "arrow.up.circle")
						.rotationEffect(.degrees(Double(nodeEnvironment.windDirection)))
						.font(detailInfoIconFont)
						.foregroundColor(.primary)
						.frame(width: detailIconSize)

					Text(windFormatted)
						.font(detailInfoTextFont)
						.foregroundColor(.primary)

					Spacer()
						.frame(width: 4)
				}

				if temp < 10 {
					Image(systemName: "thermometer.low")
						.font(detailInfoIconFont)
						.foregroundColor(nodeEnvironmentHistory?.count ?? 0 > 1 ? .blue : .primary)
						.frame(width: detailIconSize)
				}
				else if temp < 25 {
					Image(systemName: "thermometer.medium")
						.font(detailInfoIconFont)
						.foregroundColor(nodeEnvironmentHistory?.count ?? 0 > 1 ? .blue : .primary)
						.frame(width: detailIconSize)
				}
				else {
					Image(systemName: "thermometer.high")
						.font(detailInfoIconFont)
						.foregroundColor(nodeEnvironmentHistory?.count ?? 0 > 1 ? .blue : .primary)
						.frame(width: detailIconSize)
				}

				Text(tempFormatted)
					.font(detailInfoTextFont)
					.foregroundColor(.primary)

				if nodeEnvironment.barometricPressure > 0 {
					Spacer()
						.frame(width: 4)

					Image(systemName: "barometer")
						.font(detailInfoIconFont)
						.foregroundColor(nodePressureHistory?.count ?? 0 > 1 ? .red : .primary)
						.frame(width: detailIconSize)

					Text(pressureFormatted)
						.font(detailInfoTextFont)
						.foregroundColor(.primary)
				}

				if nodeEnvironment.relativeHumidity > 0, nodeEnvironment.relativeHumidity < 100 {
					Spacer()
						.frame(width: 4)

					Image(systemName: "humidity")
						.font(detailInfoIconFont)
						.foregroundColor(.primary)
						.frame(width: detailIconSize)

					Text(humidityFormatted)
						.font(detailInfoTextFont)
						.foregroundColor(.primary)
				}
			}
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var temperatureHistory: some View {
		if let nodeEnvironmentHistory, !nodeEnvironmentHistory.isEmpty {
			let yValues = getTemperatureY()

			Chart(nodeEnvironmentHistory) { measurement in
				if let time = measurement.time {
					LineMark(
						x: .value("Date", time),
						y: .value("Temperature", measurement.temperature)
					)
					.symbol {
						Circle()
							.fill(.blue)
							.frame(width: 4, height: 4)
					}
					.interpolationMethod(.cardinal(tension: 0.2))
					.foregroundStyle(.blue)
					.lineStyle(
						StrokeStyle(lineWidth: 2)
					)
				}
			}
			.chartXScale(
				domain: [
					chartHistory,
					tomorrowMidnight
				]
			)
			.chartXAxis {
				AxisMarks(
					preset: .extended,
					position: .bottom,
					values: .stride(by: .day)
				) { value in
					AxisTick()
					AxisGridLine()
					AxisValueLabel {
						if let date = value.as(Date.self) {
							Text(date, format: .dateTime.month().day())
						}
					}
				}
			}
			.chartYScale(domain: [yValues.min - yValues.margin, yValues.max + yValues.margin])
			.chartYAxis {
				AxisMarks(
					preset: .extended,
					position: .trailing,
					values: [yValues.min, yValues.center, yValues.max]
				) { value in
					AxisTick()
					AxisGridLine()
					AxisValueLabel {
						if let temperature = value.as(Float.self) {
							Text(String(format: "%.1f", temperature) + "°C")
								.lineLimit(1)
								.minimumScaleFactor(0.5)
								.frame(width: 50, alignment: .leading)
						}
					}
				}
			}
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var pressureHistory: some View {
		if let nodePressureHistory, !nodePressureHistory.isEmpty {
			let yValues = getPressureY()

			Chart(nodePressureHistory) { measurement in
				if let time = measurement.time {
					LineMark(
						x: .value("Date", time),
						y: .value("Pressure", measurement.barometricPressure)
					)
					.symbol {
						Circle()
							.fill(.red)
							.frame(width: 4, height: 4)
					}
					.interpolationMethod(.cardinal(tension: 0.2))
					.foregroundStyle(.red)
					.lineStyle(
						StrokeStyle(lineWidth: 2)
					)
				}
			}
			.chartXScale(
				domain: [
					chartHistory,
					tomorrowMidnight
				]
			)
			.chartXAxis {
				AxisMarks(
					preset: .extended,
					position: .bottom,
					values: .stride(by: .day)
				) { value in
					AxisTick()
					AxisGridLine()
					AxisValueLabel {
						if let date = value.as(Date.self) {
							Text(date, format: .dateTime.month().day())
						}
					}
				}
			}
			.chartYScale(domain: [yValues.min - yValues.margin, yValues.max + yValues.margin])
			.chartYAxis {
				AxisMarks(
					preset: .extended,
					position: .trailing,
					values: [yValues.min, yValues.center, yValues.max]
				) { value in
					AxisTick()
					AxisGridLine()
					AxisValueLabel {
						if let pressure = value.as(Float.self) {
							Text(String(format: "%.0f", pressure) + "hPa")
								.lineLimit(1)
								.minimumScaleFactor(0.5)
								.frame(width: 50, alignment: .leading)
						}
					}
				}
			}
		}
		else {
			EmptyView()
		}
	}

	@ViewBuilder
	private var nodeInfo: some View {
		if let userID = node.user?.userId {
			HStack {
				Label {
					Text("User ID")
						.textSelection(.enabled)
				} icon: {
					Image(systemName: "person")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(userID)
					.textSelection(.enabled)
			}
		}

		HStack {
			Label {
				Text("Node Number")
					.textSelection(.enabled)
			} icon: {
				Image(systemName: "number")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}

			Spacer()

			Text(String(node.num))
				.textSelection(.enabled)
		}

		if let role = node.user?.role, let deviceRole = DeviceRoles(rawValue: Int(role)) {
			HStack {
				Label {
					Text("Role")
				} icon: {
					Image(systemName: deviceRole.systemName)
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(deviceRole.name)
			}
		}

		if
			let num = connectedNode?.num,
			num != node.num
		{
			HStack {
				Label {
					Text("Network")
				} icon: {
					if node.viaMqtt {
						Image(systemName: "network")
							.symbolRenderingMode(.monochrome)
							.foregroundColor(.accentColor)
					}
					else {
						Image(systemName: "antenna.radiowaves.left.and.right")
							.symbolRenderingMode(.monochrome)
							.foregroundColor(.accentColor)
					}
				}

				Spacer()

				if node.viaMqtt {
					Text("MQTT")
				}
				else {
					VStack(alignment: .trailing, spacing: 4) {
						Text("LoRa")

						if node.rssi != 0 || node.snr != 0 {
							HStack(spacing: 8) {
								if node.rssi != 0 {
									Text("RSSI: \(node.rssi)dBm")
										.font(.system(size: 10, weight: .light))
										.foregroundColor(.gray)
								}
								if node.snr != 0 {
									Text("SNR: \(String(format: "%.1f", node.snr))dB")
										.font(.system(size: 10, weight: .light))
										.foregroundColor(.gray)
								}
							}
						}
					}
				}
			}
		}

		if let channelUtil = nodeTelemetryLast?.channelUtilization {
			HStack {
				Label {
					Text("Channel")
				} icon: {
					Image(systemName: "arrow.left.arrow.right")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(String(format: "%.2f", channelUtil) + "%")
			}
		}

		if let airUtil = nodeTelemetryLast?.airUtilTx {
			HStack {
				Label {
					Text("Air Time")
				} icon: {
					Image(systemName: "wave.3.right")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(String(format: "%.2f", airUtil) + "%")
			}
		}

		HStack {
			Label {
				Text("Hops")
			} icon: {
				Image(systemName: node.hopsAway == 0 ? "eye.circle" : "arrowshape.bounce.forward")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}

			Spacer()

			if node.hopsAway == 0 {
				Text("Direct visibility")
			}
			else if node.hopsAway == 1 {
				Text("\(node.hopsAway) hop")
			}
			else {
				Text("\(node.hopsAway) hops")
			}
		}

		if let num = connectedNode?.num, num != node.num {
			if let device = connectedDevice.device, node.num != device.num {
				let routes = node.traceRoutes?.count ?? 0

				NavigationLink {
					NavigationLazyView(
						TraceRoute(node: node)
					)
				} label: {
					Label {
						Text("Trace Route")
					} icon: {
						if routes > 0 {
							Image(systemName: "signpost.right.and.left.fill")
								.symbolRenderingMode(.monochrome)
								.foregroundColor(.accentColor)
						}
						else {
							Image(systemName: "signpost.right.and.left")
								.symbolRenderingMode(.monochrome)
								.foregroundColor(.accentColor)
						}
					}
				}
			}

			if let user = node.user {
				let publicKey = user.publicKey
				let keyMatch = KeyMatch.fromInt(user.keyMatch)

				HStack {
					Label {
						Text("Messages")
					} icon: {
						if user.pkiEncrypted, let publicKey, !publicKey.isEmpty {
							switch keyMatch {
							case .notSet:
								Image(systemName: "lock.trianglebadge.exclamationmark")
									.symbolRenderingMode(.monochrome)
									.foregroundColor(.accentColor)

							case .notMatching:
								Image(systemName: "lock.slash")
									.symbolRenderingMode(.monochrome)
									.foregroundColor(.accentColor)

							case .matching:
								Image(systemName: "lock")
									.symbolRenderingMode(.monochrome)
									.foregroundColor(.accentColor)
							}
						}
						else {
							Image(systemName: "lock.open")
								.symbolRenderingMode(.monochrome)
								.foregroundColor(.accentColor)
						}
					}

					Spacer()

					if user.pkiEncrypted, let publicKey, !publicKey.isEmpty {
						switch keyMatch {
						case .notSet:
							HStack(alignment: .center, spacing: 8) {
								Circle()
									.foregroundStyle(Color.gray)
									.frame(width: statusDotSize, height: statusDotSize)

								VStack(alignment: .trailing, spacing: 4) {
									Text("Received public key")

									keyPreview(key: publicKey)
								}
							}

						case .notMatching:
							HStack(alignment: .center, spacing: 8) {
								Circle()
									.foregroundStyle(Color.red)
									.frame(width: statusDotSize, height: statusDotSize)

								VStack(alignment: .trailing, spacing: 4) {
									Text("Compromised")

									VStack(alignment: .trailing, spacing: 4) {
										Text("Node & message keys do not match")
											.font(.system(size: 10, weight: .light))
											.foregroundColor(.red)
									}
								}
							}

						case .matching:
							HStack(alignment: .center, spacing: 8) {
								Circle()
									.foregroundStyle(Color.green)
									.frame(width: statusDotSize, height: statusDotSize)

								VStack(alignment: .trailing, spacing: 4) {
									Text("Encrypted")

									keyPreview(key: publicKey)
								}
							}
						}
					}
					else {
						HStack(alignment: .center, spacing: 8) {
							Circle()
								.foregroundStyle(Color.orange)
								.frame(width: statusDotSize, height: statusDotSize)

							Text("Not secured")
						}
					}
				}
			}
		}

		if
			let lastHeard = node.lastHeard,
			lastHeard.timeIntervalSince1970 > 0
		{
			HStack {
				Label {
					Text("Last Heard")
				} icon: {
					Image(systemName: "heart")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				VStack(alignment: .trailing, spacing: 4) {
					Text(lastHeard.relative())
						.textSelection(.enabled)

					lastHeardBy
				}
			}
		}

		if
			let firstHeard = node.firstHeard,
			firstHeard.timeIntervalSince1970 > 0
		{
			HStack {
				Label {
					Text("First Heard")
				} icon: {
					Image(systemName: "eye.circle")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(firstHeard.relative())
					.textSelection(.enabled)
			}
		}

		if let hwModel = node.user?.hwModel {
			HStack {
				Label {
					Text("Hardware")
				} icon: {
					Image(systemName: "flipphone")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(hwModel)
			}
		}

		if let metadata = node.metadata, let firmwareVersion = metadata.firmwareVersion {
			HStack {
				Label {
					Text("Firmware")
				} icon: {
					Image(systemName: "memorychip")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text("v" + firmwareVersion)
			}
		}

		if let nodeTelemetryLast, nodeTelemetryLast.uptimeSeconds > 0 {
			let now = Date.now
			let later = now + TimeInterval(nodeTelemetryLast.uptimeSeconds)
			let uptimeFormatted = (now..<later).formatted(.components(style: .narrow))

			HStack {
				Label {
					Text("Uptime")
				} icon: {
					Image(systemName: "hourglass")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}

				Spacer()

				Text(uptimeFormatted)
					.textSelection(.enabled)
			}
		}
	}

	@ViewBuilder
	private var actions: some View {
		if let device = connectedDevice.device, node.num != device.num {
			Section(
				header: Text("Actions").fontDesign(.rounded)
			) {
				ExchangePositionsButton(
					node: node
				)

				if let connectedNode {
					DeleteNodeButton(
						node: node,
						nodeConfig: nodeConfig,
						connectedNode: connectedNode,
						context: context
					)
				}
			}
			.headerProminence(.increased)
		}
	}

	@ViewBuilder
	private var lastHeardBy: some View {
		if let shortName = node.lastHeardBy?.user?.shortName {
			HStack(alignment: .center, spacing: 4) {
				Image(systemName: "flipphone")
					.font(.system(size: 10, weight: .bold))
					.foregroundColor(.gray)

				Text(shortName)
					.font(.system(size: 10, weight: .light))
					.foregroundColor(.gray)

				if
					let distance = locationManager.getDistanceFormatted(
						latitude: node.lastHeardAtLatitude,
						longitude: node.lastHeardAtLongitude
					),
					let bearing = locationManager.getBearing(
						latitude: node.lastHeardAtLatitude,
						longitude: node.lastHeardAtLongitude
					)
				{
					Spacer()
						.frame(width: 4)

					Image(systemName: "location.north.circle")
						.font(.system(size: 10, weight: .bold))
						.foregroundColor(.gray)
						.rotationEffect(
							Angle(degrees: bearing)
						)

					Text("\(distance) away")
						.font(.system(size: 10, weight: .light))
						.foregroundColor(.gray)
				}
			}
		}
		else {
			EmptyView()
		}
	}

	init(
		node: NodeInfoEntity,
		isInSheet: Bool = false
	) {
		self.node = node
		self.isInSheet = isInSheet
	}

	@ViewBuilder
	private func admin(node: NodeInfoEntity, metadata: DeviceMetadataEntity) -> some View {
		if let user = node.user, let myInfo = node.myInfo, myInfo.hasAdmin {
			Button {
				let adminMessageId = nodeConfig.requestDeviceMetadata(
					to: user,
					from: user,
					index: myInfo.adminIndex,
					context: context
				)

				if adminMessageId > 0 {
					Logger.mesh.info("Sent node metadata request from node details")
				}
			} label: {
				Label {
					Text("Refresh Device Metadata")
				} icon: {
					Image(systemName: "arrow.clockwise")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}
			}
		}

		Button {
			showingRebootConfirm = true
		} label: {
			Label {
				Text("Reboot")
			} icon: {
				Image(systemName: "arrow.triangle.2.circlepath")
					.symbolRenderingMode(.monochrome)
					.foregroundColor(.accentColor)
			}
		}.confirmationDialog(
			"are.you.sure",
			isPresented: $showingRebootConfirm
		) {
			Button("reboot.node", role: .destructive) {
				if
					let user = node.user,
					let myInfo = node.myInfo,
					!nodeConfig.sendReboot(fromUser: user, toUser: user, adminIndex: myInfo.adminIndex)
				{
					Logger.mesh.warning("Reboot Failed")
				}
			}
		}

		if metadata.canShutdown {
			Button {
				showingShutdownConfirm = true
			} label: {
				Label {
					Text("Shut Down")
				} icon: {
					Image(systemName: "power")
						.symbolRenderingMode(.monochrome)
						.foregroundColor(.accentColor)
				}
			}.confirmationDialog(
				"are.you.sure",
				isPresented: $showingShutdownConfirm
			) {
				Button("Shut Down Node?", role: .destructive) {
					if
						let user = node.user,
						let myInfo = node.myInfo,
						!nodeConfig.sendShutdown(fromUser: user, toUser: user, adminIndex: myInfo.adminIndex)
					{
						Logger.mesh.warning("Shutdown Failed")
					}
				}
			}
		}
	}

	@ViewBuilder
	private func keyPreview(key: Data) -> some View {
		HStack(alignment: .center, spacing: 4) {
			Image(systemName: "key.horizontal.fill")
				.font(.system(size: 10, weight: .bold))
				.foregroundColor(.gray)

			Text(key.hexString().hashPreview(maxLength: 16))
				.lineLimit(1)
				.font(.system(size: 10, weight: .regular))
				.foregroundColor(.gray)
		}
	}

	// TODO: consolidate next four funcs
	private func findTemperatureMinMax() -> (min: Float, max: Float) {
		let lowerBound: Float = -50.0
		let upperBound: Float = 150.0

		guard let nodeEnvironmentHistory else {
			return (min: lowerBound, max: upperBound)
		}

		var min = upperBound
		var max = lowerBound

		let history = nodeEnvironmentHistory.filter { measurement in
			lowerBound...upperBound ~= measurement.temperature
		}

		if history.isEmpty {
			return (min: lowerBound, max: upperBound)
		}
		else if history.count == 1 {
			min = history[0].temperature
			max = history[0].temperature
		}
		else {
			for measurement in history {
				if measurement.temperature < min {
					min = measurement.temperature
				}
				if measurement.temperature > max {
					max = measurement.temperature
				}
			}
		}

		return (min: min, max: max)
	}

	private func findPresureMinMax() -> (min: Float, max: Float) {
		let lowerBound: Float = 960.0
		let upperBound: Float = 1070.0

		guard let nodeEnvironmentHistory else {
			return (min: lowerBound, max: upperBound)
		}

		var min = upperBound
		var max = lowerBound

		let history = nodeEnvironmentHistory.filter { measurement in
			lowerBound...upperBound ~= measurement.barometricPressure
		}

		if history.isEmpty {
			return (min: lowerBound, max: upperBound)
		}
		else if history.count == 1 {
			min = history[0].temperature
			max = history[0].temperature
		}
		else {
			for measurement in history {
				if measurement.barometricPressure < min {
					min = measurement.barometricPressure
				}
				if measurement.barometricPressure > max {
					max = measurement.barometricPressure
				}
			}
		}

		return (min: min, max: max)
	}

	// swiftlint:disable:next large_tuple
	private func getTemperatureY() -> (min: Int, center: Int, max: Int, margin: Int) {
		let overshootMin: Float = 1.0
		let extrema = findTemperatureMinMax()

		let overshoot = min(overshootMin, (extrema.max - extrema.min) / 3.0)
		let overshootInt = Int(ceil(overshoot))

		var chartMin = Int(floor(extrema.min - overshoot))
		let chartCenter = Int((extrema.min + (extrema.max - extrema.min) / 2.0).rounded())
		var chartMax = Int(ceil(extrema.max + overshoot))

		let deltaMin = chartCenter - chartMin
		let deltaMax = chartMax - chartCenter
		if deltaMin > deltaMax {
			chartMax = chartCenter + deltaMin
		}
		else {
			chartMin = chartCenter - deltaMax
		}

		// TODO: make it struct
		return (min: chartMin, center: chartCenter, max: chartMax, margin: overshootInt)
	}

	// swiftlint:disable:next large_tuple
	private func getPressureY() -> (min: Int, center: Int, max: Int, margin: Int) {
		let overshootMin: Float = 2.0
		let extrema = findPresureMinMax()

		let overshoot = min(overshootMin, (extrema.max - extrema.min) / 3.0)
		let overshootInt = Int(ceil(overshoot))

		var chartMin = Int(floor(extrema.min - overshoot))
		let chartCenter = Int((extrema.min + (extrema.max - extrema.min) / 2.0).rounded())
		var chartMax = Int(ceil(extrema.max + overshoot))

		let deltaMin = chartCenter - chartMin
		let deltaMax = chartMax - chartCenter
		if deltaMin > deltaMax {
			chartMax = chartCenter + deltaMin
		}
		else {
			chartMin = chartCenter - deltaMax
		}

		// TODO: make it struct
		return (min: chartMin, center: chartCenter, max: chartMax, margin: overshootInt)
	}
}
// swiftlint:enable file_length
