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
	private var appDelegate
	@Environment(\.scenePhase)
	private var scenePhase
	@State
	private var onboardingDone: Bool = UserDefaults.onboardingDone
	@State
	private var channelSettings: String?
	@State
	private var addChannels = false

	private let appState: AppState
	private let bleManager: BLEManager
	private let bleActions: BLEActions
	private let nodeConfig: NodeConfig
	private let locationManager: LocationManager
	private let persistence: NSPersistentContainer

	@ViewBuilder
	var body: some Scene {
		WindowGroup {
			if !onboardingDone {
				Onboarding(done: $onboardingDone)
			}
			else {
				Content()
					.environment(\.managedObjectContext, persistence.viewContext)
					.environmentObject(bleManager)
					.environmentObject(bleManager.currentDevice)
					.environmentObject(bleActions)
					.environmentObject(nodeConfig)
					.environmentObject(locationManager)
					.onOpenURL { url in
						if url.scheme == AppConstants.meowtasticScheme {
							AppState.shared.navigation = Navigation(from: url)
						}
					}
			}
		}
		.onChange(of: scenePhase, initial: true) {
			guard onboardingDone else {
				return
			}

			if scenePhase == .background {
				try? Persistence.shared.container.viewContext.save()

				let processInfo = ProcessInfo.processInfo
				bleManager.stopScanning()
				if UserDefaults.powerSavingMode || processInfo.isLowPowerModeEnabled {
					bleManager.disconnectDevice()
					bleManager.automaticallyReconnect = false
				}
				else {
					bleManager.automaticallyReconnect = true
				}

				scheduleAppRefresh()
			}
			else {
				cancelAppRefresh()

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

	private func cancelAppRefresh() {
		BGTaskScheduler.shared.cancelAllTaskRequests()
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
