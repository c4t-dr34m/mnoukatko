import BackgroundTasks
import CoreBluetooth
import CoreData
import FirebaseAnalytics
import OSLog
import SwiftUI

@main
struct Meowtastic: App {
	private static let bgTaskLifespan: TimeInterval = 2 * 60 // 2 minutes

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

				scheduleAppRefresh()
			}
		}
		.backgroundTask(.appRefresh(AppConstants.backgroundTaskID)) {
			Logger.app.debug("Background task started")
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

		do {
			try BGTaskScheduler.shared.submit(request)

			Logger.app.debug("Background task scheduled")
		}
		catch let error {
			Logger.app.warning("Failed to schedule background task: \(error.localizedDescription)")
		}
	}

	private func refreshApp() async {
		scheduleAppRefresh()

		let bgTaskStarted = Date.now
		let watcher = BLEWatcher(bleManager: bleManager)
		watcher.start()

		while
			Date.now < bgTaskStarted.addingTimeInterval(Self.bgTaskLifespan)
				&& !watcher.allTasksDone()
		{
			// TODO: record some key changes in ble manager
			sleep(1)
		}

		Logger.app.warning(
			"Background task finished in \(bgTaskStarted.distance(to: .now))s. Tasks done: \(watcher.tasksDone)"
		)

		Analytics.logEvent(
			AnalyticEvents.backgroundFinished.id,
			parameters: [
				"tasks_done": watcher.allTasksDone()
			]
		)
	}
}
