import CoreBluetooth
import CoreLocation
import SwiftUI

struct Onboarding: View {
	private let locationManager = CLLocationManager()
	private let notificationManager = UNUserNotificationCenter.current()

	@State
	private var hasLocation: Bool = false
	@State
	private var hasNotifications: Bool = false
	@State
	private var permissionUpdateTimer: Timer?
	@Binding
	private var done: Bool

	@ViewBuilder
	var body: some View {
		VStack(alignment: .center) {
			Text("Before We Start")
				.font(.largeTitle)

			Spacer()

			VStack(alignment: .leading, spacing: 8) {
				Label {
					Text("Location")
						.font(.title2)
				} icon: {
					Image(systemName: "mappin.and.ellipse")
						.font(.title2)
						.frame(width: 24, height: 24)
						.foregroundStyle(hasLocation ? Color.green : Color.gray)
				}

				HStack {
					Text("Meowtastic would like to use your current location to determine where you are on the map, how far are other Meshtastic® nodes, and, optionally, feed your node with location updates.")
						.font(.callout)
						.foregroundStyle(.gray)
						.padding(.leading, 32)

					Spacer()
				}

				HStack {
					Spacer()

					Button(action: {
						authorizeLocation()
					}) {
						Text(hasLocation ? "Done" : "Allow Location")
					}
					.disabled(hasLocation)
					.buttonStyle(.bordered)
					.buttonBorderShape(.capsule)
					.controlSize(.regular)
				}
			}

			Divider()

			VStack(alignment: .leading, spacing: 8) {
				Label {
					Text("Notifications")
						.font(.title2)
				} icon: {
					Image(systemName: "app.badge")
						.font(.title2)
						.frame(width: 24, height: 24)
						.foregroundStyle(hasNotifications ? Color.green : Color.gray)
				}

				HStack {
					Text("Meowtastic also would like to deliver you notifications in case it discovers new Meshtastic® node, or when you got a new message. You can customize which notifications you would like later in Options.")
						.font(.callout)
						.foregroundStyle(.gray)
						.padding(.leading, 32)

					Spacer()
				}

				HStack {
					Spacer()

					Button(action: {
						authorizeNotifications()
					}) {
						Text(hasNotifications ? "Done" : "Allow Notifications")
					}
					.disabled(hasNotifications)
					.buttonStyle(.bordered)
					.buttonBorderShape(.capsule)
					.controlSize(.regular)
				}
			}

			Spacer()

			Button(action: {
				UserDefaults.onboardingDone = true
				NotificationCenter.default.post(
					name: .onboardingDone,
					object: nil
				)

				done = true
			}) {
				Text("Continue")
					.disabled(!hasLocation || !hasNotifications)
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.capsule)
			.controlSize(.large)
		}
		.padding(.all, 16)
		.onAppear {
			permissionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
				checkAuthorizations()
			}
		}
		.onDisappear {
			permissionUpdateTimer?.invalidate()
		}
	}

	init(done: Binding<Bool>) {
		self._done = done
	}

	private func checkAuthorizations() {
		hasLocation = [.authorizedWhenInUse, .authorizedAlways].contains(locationManager.authorizationStatus)
		notificationManager.getNotificationSettings { settings in
			self.hasNotifications = settings.authorizationStatus == .authorized
		}
	}

	private func authorizeLocation() {
		locationManager.requestAlwaysAuthorization()
	}

	private func authorizeNotifications() {
		UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		) { granted, error in
			guard granted, error == nil else {
				return
			}

			checkAuthorizations()
		}
	}
}
