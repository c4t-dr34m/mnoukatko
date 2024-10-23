import BackgroundTasks
import CoreBluetooth
import CoreData
import FirebaseAnalytics
import OSLog
import SwiftUI

@main
struct Meowtastic: App {
	private static let bgTaskStartDelay: TimeInterval = 10 * 60
	private static let bgTaskLifespan: TimeInterval = 90

	@UIApplicationDelegateAdaptor(MeowtasticDelegate.self)
	var appDelegate
	@Environment(\.scenePhase)
	var scenePhase
	@State
	var incomingUrl: URL?
	@State
	var channelSettings: String?
	@State
	var addChannels = false

	private let appState: AppState
	private let bleManager: BLEManager
	private let bleActions: BLEActions
	private let nodeConfig: NodeConfig
	private let locationManager: LocationManager
	private let persistence: NSPersistentContainer

	@ViewBuilder
	var body: some Scene {
		WindowGroup {
			Content()
				.environment(\.managedObjectContext, persistence.viewContext)
				.environmentObject(bleManager)
				.environmentObject(bleManager.currentDevice)
				.environmentObject(bleActions)
				.environmentObject(nodeConfig)
				.environmentObject(locationManager)
				.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
					Logger.mesh.debug("URL received \(userActivity)")

					incomingUrl = userActivity.webpageURL

					if
						incomingUrl?.absoluteString.lowercased().contains("meshtastic.org/e/#") != nil,
						let components = incomingUrl?.absoluteString.components(separatedBy: "#")
					{
						addChannels = Bool(incomingUrl?["add"] ?? "false") ?? false

						if incomingUrl?.absoluteString.lowercased().contains("?") != nil {
							guard let cs = components.last?.components(separatedBy: "?").first else {
								return
							}

							channelSettings = cs
						}
						else {
							guard let cs = components.first else {
								return
							}

							channelSettings = cs
						}

						Logger.services.debug("Add Channel \(addChannels)")
					}
				}
				.onOpenURL { url in
					Logger.mesh.debug("Some sort of URL was received \(url)")

					incomingUrl = url

					if url.absoluteString.lowercased().contains("meshtastic.org/e/#") {
						if let components = incomingUrl?.absoluteString.components(separatedBy: "#") {
							addChannels = Bool(incomingUrl?["add"] ?? "false") ?? false

							if incomingUrl?.absoluteString.lowercased().contains("?") != nil {
								guard let cs = components.last?.components(separatedBy: "?").first else {
									return
								}

								channelSettings = cs
							}
							else {
								guard let cs = components.first else {
									return
								}

								channelSettings = cs
							}

							Logger.services.debug("Add Channel \(addChannels)")
						}

						Logger.mesh.debug(
							"User wants to open a Channel Config: \(incomingUrl?.absoluteString ?? "No QR Code Link")"
						)
					}
					else if url.absoluteString.lowercased().contains("meshtastic:///") {
						appState.navigationPath = url.absoluteString

						let path = appState.navigationPath ?? ""
						if path.starts(with: "meshtastic:///map") {
							AppState.shared.tabSelection = TabTag.map
						}
						else if path.starts(with: "meshtastic:///nodes") {
							AppState.shared.tabSelection = TabTag.nodes
						}
					}
				}
		}
		.onChange(of: scenePhase, initial: false) {
			if scenePhase == .background {
				try? Persistence.shared.container.viewContext.save()

				bleManager.stopScanning()
				bleManager.disconnectDevice(reconnect: false)

				scheduleAppRefresh()
			}
			else {
				bleManager.automaticallyReconnect = true
				bleManager.startScanning()
			}
		}
		.backgroundTask(.appRefresh(AppConstants.backgroundTaskID)) {
			Analytics.logEvent(AnalyticEvents.backgroundUpdate.id, parameters: nil)

			await refreshApp()
		}
	}

	init() {
		self.persistence = Persistence.shared.container
		self.locationManager = LocationManager.shared

		let appState = AppState()
		let bleManager = BLEManager(
			appState: appState,
			context: persistence.viewContext
		)
		let bleActions = BLEActions(
			bleManager: bleManager
		)
		let nodeConfig = NodeConfig(
			bleManager: bleManager,
			context: persistence.viewContext
		)

		self.appState = appState
		self.bleManager = bleManager
		self.bleActions = bleActions
		self.nodeConfig = nodeConfig
	}

	private func scheduleAppRefresh() {
		let request = BGProcessingTaskRequest(identifier: AppConstants.backgroundTaskID)
		request.requiresNetworkConnectivity = false
		request.requiresExternalPower = false
		request.earliestBeginDate = .now.addingTimeInterval(Self.bgTaskStartDelay)

		do {
			try BGTaskScheduler.shared.submit(request)

			Logger.app.debug("Background task scheduled")
		}
		catch let error {
			Logger.app.warning("Failed to schedule background task: \(error.localizedDescription)")
		}
	}

	private func refreshApp() async {
		let bgTaskStarted = Date.now
		let watcher = BackgroundWatcher(bleManager: bleManager)

		Timer.scheduledTimer(withTimeInterval: Self.bgTaskLifespan, repeats: false) { _ in
			watcher.stopBackground(runtime: bgTaskStarted.distance(to: .now))
		}

		scheduleAppRefresh()
		watcher.startBackground()
	}
}
