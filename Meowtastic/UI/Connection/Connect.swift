import CoreBluetooth
import CoreData
import CoreLocation
import FirebaseAnalytics
import OSLog
import SwiftUI

struct Connect: View {
	private let isInSheet: Bool
	private let deviceFont = Font.system(size: 18, weight: .regular, design: .rounded)
	private let detailInfoFont = Font.system(size: 14, weight: .regular, design: .rounded)
	private let debounce = Debounce<() async -> Void>(duration: .milliseconds(500)) { action in
		await action()
	}
	private let nonNodeEvents = 20

	@Environment(\.managedObjectContext)
	private var context
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@EnvironmentObject
	private var bleManager: BLEManager
	@State
	private var node: NodeInfoEntity?
	@State
	private var visibleDevices: [Device]
	@State
	private var invalidFirmwareVersion = false
	@State
	private var degreesRotating = 0.0
	@State
	private var showProgress = true

	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(key: "favorite", ascending: false),
			NSSortDescriptor(key: "user.longName", ascending: true)
		],
		animation: .default
	)
	private var nodes: FetchedResults<NodeInfoEntity>

	var body: some View {
		NavigationStack {
			List {
				Section(
					header: Text("Bluetooth").fontDesign(.rounded)
				) {
					connection
				}
				.headerProminence(.increased)

				Section(
					header: Text("Visible Devices").fontDesign(.rounded)
				) {
					if !visibleDevices.isEmpty {
						visible
					}
					else {
						Text("None")
					}
				}
				.headerProminence(.increased)
			}
			.navigationTitle("Connection")
			.navigationBarTitleDisplayMode(.large)
			.navigationBarItems(
				trailing: ConnectionInfo()
			)
		}
		.onAppear {
			showProgress = true
			bleManager.startScanning()

			Analytics.logEvent(
				AnalyticEvents.connect.id,
				parameters: [
					"sheet": isInSheet,
					"visible_devices": visibleDevices.count
				]
			)
		}
		.onDisappear {
			UserDefaults.lastConnectionEventCount = bleManager.infoChangeCount
			Logger.app.debug("Connection event count stored: \(UserDefaults.lastConnectionEventCount)")

			bleManager.stopScanning()
		}
		.onChange(of: bleManager.devices, initial: true) {
			debounce.emit {
				await loadPeripherals()
				await fetchNodeInfo()
			}
		}
		.onChange(of: bleManager.isConnected, initial: true) {
			handleConnectionState()

			debounce.emit {
				await loadPeripherals()
				await fetchNodeInfo()
			}
		}
		.onChange(of: bleManager.isSubscribed) {
			handleConnectionState()

			debounce.emit {
				await loadPeripherals()
				await fetchNodeInfo()
			}
		}
		.onChange(of: bleManager.isInvalidFwVersion) {
			invalidFirmwareVersion = bleManager.isInvalidFwVersion
		}
		.sheet(
			isPresented: $invalidFirmwareVersion,
			onDismiss: didDismissSheet
		) {
			InvalidVersion(
				minimumVersion: bleManager.minimumVersion,
				version: bleManager.connectedVersion
			)
			.presentationDetents([.medium])
			.presentationDragIndicator(.automatic)
		}
	}

	@ViewBuilder
	private var connection: some View {
		Section {
			overallStatus
			connectedDevice
		}
	}

	@ViewBuilder
	private var overallStatus: some View {
		HStack(alignment: .top, spacing: 8) {
			bluetoothAvatar
			bluetoothStatus
		}
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			Button(role: .destructive) {
				bleManager.cancelPeripheralConnection()
			} label: {
				Label(
					"Abort",
					systemImage: "antenna.radiowaves.left.and.right.slash"
				)
			}
		}
	}

	@ViewBuilder
	private var connectedDevice: some View {
		if
			let device = bleManager.getConnectedDevice(),
			device.peripheral.state == .connected || device.peripheral.state == .connecting
		{
			let node = nodes.first(where: { node in
				node.num == device.num
			})

			HStack(alignment: .top, spacing: 8) {
				connectionAvatar(for: node)

				VStack(alignment: .leading, spacing: 8) {
					if node != nil {
						Text(device.longName)
							.fontWeight(.medium)
							.font(.title2)
							.lineLimit(1)
							.minimumScaleFactor(0.5)
					}
					else {
						Text("N/A")
							.fontWeight(.medium)
							.font(.title2)
							.lineLimit(1)
							.minimumScaleFactor(0.5)
					}

					HStack(spacing: 8) {
						SignalStrengthIndicator(
							signalStrength: device.getSignalStrength(),
							size: 14,
							color: .gray
						)

						if let name = device.peripheral.name {
							Text(name)
								.font(detailInfoFont)
								.foregroundColor(.gray)
						}
					}

					if
						let loRaConfig = node?.loRaConfig,
						loRaConfig.regionCode == RegionCodes.unset.rawValue
					{
						HStack(spacing: 8) {
							Image(systemName: "gear.badge.xmark")
								.font(detailInfoFont)
								.foregroundColor(.gray)
								.frame(width: 14)

							Text("LoRa region is not set")
								.font(detailInfoFont)
								.foregroundColor(.gray)
						}
					}

					HStack(spacing: 8) {
						Image(systemName: "flipphone")
							.font(detailInfoFont)
							.foregroundColor(.gray)
							.frame(width: 14)

						if let hwModel = node?.user?.hwModel {
							Text(hwModel)
								.font(detailInfoFont)
								.foregroundColor(.gray)
						}
						else {
							Text("Unknown hardware")
								.font(detailInfoFont)
								.foregroundColor(.gray)
						}

						if let version = node?.metadata?.firmwareVersion {
							Text("v\(version)")
								.font(detailInfoFont)
								.foregroundColor(.gray)
						}
					}

					if
						let info = bleManager.info,
						let infoLastChanged = bleManager.infoLastChanged,
						!info.isEmpty
					{
						HStack(alignment: .center, spacing: 8) {
							Image(systemName: "info.circle.fill")
								.font(detailInfoFont)
								.foregroundColor(.gray)
								.frame(width: 14)

							VStack(alignment: .leading, spacing: 2) {
								if infoLastChanged.isStale(threshold: 30) {
									let diff = infoLastChanged.distance(to: .now)

									Text("Nothing for last \(String(format: "%.0f", diff))s")
										.lineLimit(1)
										.font(detailInfoFont)
										.foregroundColor(.gray)
								}
								else {
									Text(info)
										.lineLimit(1)
										.font(detailInfoFont)
										.foregroundColor(.gray)
								}

								if showProgress {
									let value = getConnectionProgress(nodeCount: nodes.count)

									Gauge(
										value: value,
										in: 0.0...1.0
									) { }
										.gaugeStyle(.accessoryLinearCapacity)
										.tint(.gray)
										.id("connection_progress")
								}
							}
						}
					}
				}
			}
			.swipeActions(edge: .trailing, allowsFullSwipe: true) {
				Button(role: .destructive) {
					if device.peripheral.state == .connected {
						bleManager.disconnectDevice(reconnect: false)
					}
				} label: {
					Label(
						"Disconnect",
						systemImage: "antenna.radiowaves.left.and.right.slash"
					)
				}
			}
		}
	}

	@ViewBuilder
	private var bluetoothAvatar: some View {
		let on = bleManager.isSwitchedOn
		let connecting = bleManager.isConnecting
		let connected = bleManager.isConnected

		ZStack(alignment: .top) {
			if on {
				if connected {
					AvatarAbstract(
						icon: "checkmark.circle",
						color: .green,
						size: 64
					)
					.padding([.top, .bottom, .trailing], 10)
				}
				else if connecting {
					AvatarAbstract(
						icon: "hourglass.circle",
						color: .accentColor,
						size: 64
					)
					.padding([.top, .bottom, .trailing], 10)
				}
				else {
					AvatarAbstract(
						icon: "circle.dotted",
						color: .red,
						size: 64
					)
					.padding([.top, .bottom, .trailing], 10)
				}
			}
			else {
				AvatarAbstract(
					icon: "nosign",
					color: .gray,
					size: 64
				)
				.padding([.top, .bottom, .trailing], 10)
			}
		}
		.frame(width: 80, height: 80)
	}

	@ViewBuilder
	private var bluetoothStatus: some View {
		let on = bleManager.isSwitchedOn
		let connecting = bleManager.isConnecting
		let connected = bleManager.isConnected

		VStack(alignment: .leading, spacing: 8) {
			Text("Bluetooth")
				.font(.title2)

			if on {
				if connected {
					Text("Connected")
						.font(detailInfoFont)
						.foregroundColor(.gray)
				}
				else if connecting {
					Text("Connecting")
						.font(detailInfoFont)
						.foregroundColor(.gray)
				}
				else {
					Text("Not Connected")
						.font(detailInfoFont)
						.foregroundColor(.gray)

					if bleManager.timeoutCount > 0 {
						Text("Attempt: \(bleManager.timeoutCount) of 10")
							.font(detailInfoFont)
							.foregroundColor(.gray)
					}

					if bleManager.lastConnectionError.count > 0 {
						Text(bleManager.lastConnectionError)
							.font(detailInfoFont)
							.foregroundColor(.gray)
					}
				}
			}
			else {
				Text("Bluetooth is Disabled")
					.font(detailInfoFont)
					.foregroundColor(.gray)
			}
		}
	}

	@ViewBuilder
	private var visible: some View {
		ForEach(visibleDevices) { device in
			Button {
				bleManager.connectTo(peripheral: device.peripheral)
			} label: {
				HStack(alignment: .center, spacing: 16) {
					HStack(spacing: 16) {
						SignalStrengthIndicator(
							signalStrength: device.getSignalStrength(),
							size: 14,
							color: .gray
						)

						if let name = device.peripheral.name {
							Text(name)
								.font(deviceFont)
								.foregroundColor(.gray)
						}
						else {
							Text(device.name)
								.font(deviceFont)
								.foregroundColor(.gray)
						}
					}

					if UserDefaults.preferredPeripheralId == device.peripheral.identifier.uuidString {
						Spacer()

						Image(systemName: "star.fill")
							.font(deviceFont)
							.foregroundColor(.gray)
					}
				}
			}
		}
	}

	init(
		node: NodeInfoEntity? = nil,
		isInSheet: Bool = false
	) {
		self.node = node
		self.isInSheet = isInSheet
		self.visibleDevices = []

		UNUserNotificationCenter.current().getNotificationSettings(
			completionHandler: { settings in
				if settings.authorizationStatus == .notDetermined {
					UNUserNotificationCenter.current().requestAuthorization(
						options: [.alert, .badge, .sound]
					) { success, error in
						if success {
							Logger.services.info("Notifications are all set!")
						}
						else if let error = error {
							Logger.services.error("\(error.localizedDescription)")
						}
					}
				}
			}
		)
	}

	@ViewBuilder
	private func connectionAvatar(for node: NodeInfoEntity?) -> some View {
		ZStack(alignment: .top) {
			let nodeColor = node?.color ?? (colorScheme == .dark ? .white : .gray)

			if let node {
				AvatarNode(
					node,
					ignoreOffline: true,
					size: 64
				)
				.padding([.top, .bottom, .trailing], 10)
			}
			else {
				AvatarAbstract(
					icon: "questionmark",
					size: 64
				)
				.padding([.top, .bottom, .trailing], 10)
			}

			if bleManager.isConnecting {
				HStack(spacing: 0) {
					Spacer()
					Image(systemName: "magnifyingglass.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(nodeColor)
						.background(
							Circle()
								.foregroundColor(nodeColor.isLight() ? .black : .white)
						)
				}
			}
			else if bleManager.isConnected, !bleManager.isSubscribed {
				HStack(spacing: 0) {
					Spacer()
					Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(nodeColor)
						.rotationEffect(.degrees(degreesRotating))
						.background(
							Circle()
								.foregroundColor(.listBackground(for: colorScheme))
						)
						.onAppear {
							withAnimation(
								.linear(duration: 1)
								.speed(0.3)
								.repeatForever(autoreverses: false)
							) {
								degreesRotating = 360.0
							}
						}
				}
			}
			else if bleManager.isSubscribed {
				HStack(spacing: 0) {
					Spacer()
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 24))
						.foregroundColor(nodeColor)
						.background(
							Circle()
								.foregroundColor(.listBackground(for: colorScheme))
						)
				}
			}
		}
		.frame(width: 80, height: 80)
	}

	private func loadPeripherals() async {
		// swiftlint:disable:next force_unwrapping
		let visibleDuration = Calendar.current.date(byAdding: .second, value: -5, to: .now)!
		let devices = bleManager.devices.filter { device in
			device.lastUpdate >= visibleDuration
		}

		visibleDevices = devices.sorted(by: {
			$0.name < $1.name
		})
	}

	private func fetchNodeInfo() async {
		let fetchNodeInfoRequest = NodeInfoEntity.fetchRequest()
		fetchNodeInfoRequest.predicate = NSPredicate(
			format: "num == %lld",
			Int64(bleManager.getConnectedDevice()?.num ?? -1)
		)

		node = try? context.fetch(fetchNodeInfoRequest).first
	}

	private func didDismissSheet() {
		bleManager.disconnectDevice(reconnect: false)
	}

	private func handleConnectionState() {
		if bleManager.isSubscribed, bleManager.isConnected {
			showProgress = false
		}
	}

	private func getConnectionProgress(nodeCount: Int) -> Float {
		let previousEventCount = UserDefaults.lastConnectionEventCount
		let expectedEventCount = nonNodeEvents + min(nodeCount, 100)
		let maxCount: Int

		if Float(abs(previousEventCount - expectedEventCount)) < (Float(expectedEventCount) * 0.8) {
			maxCount = previousEventCount
		}
		else {
			maxCount = expectedEventCount
		}

		return min(
			Float(bleManager.infoChangeCount) / Float(maxCount),
			1.0
		)
	}
}
