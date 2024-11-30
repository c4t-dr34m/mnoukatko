/*
Mňoukátko - the Meshtastic® client

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
import CoreBluetooth
import CoreLocation
import SwiftUI

struct Onboarding: View {
	private let locationManager = CLLocationManager()
	private let notificationManager = UNUserNotificationCenter.current()

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@State
	private var hasLocation: Bool = false
	@State
	private var hasNotifications: Bool = false
	@State
	private var permissionUpdateTimer: Timer?
	@Binding
	private var done: Bool

	private var hasPermissions: Bool {
		hasLocation && hasNotifications
	}

	@ViewBuilder
	var body: some View {
		ZStack {
			Rectangle()
				.ignoresSafeArea()
				.overlay(
					Image("Mňoukátko")
						.resizable()
						.ignoresSafeArea()
						.aspectRatio(contentMode: .fill)
				)

			VStack(alignment: .center) {
				Text("Before We Start")
					.font(.largeTitle)

				Spacer()

				VStack {
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
							Text("Mňoukátko would like to use your current location to determine where you are on the map, how far are other Meshtastic® nodes, and, optionally, feed your node with location updates.")
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
								Text(hasLocation ? "Done" : "Next")
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
							Text("Mňoukátko also would like to deliver you notifications in case it discovers new Meshtastic® node, or when you got a new message. You can customize which notifications you would like later in Options.")
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
								Text(hasNotifications ? "Done" : "Next")
							}
							.disabled(!hasLocation || hasNotifications)
							.buttonStyle(.bordered)
							.buttonBorderShape(.capsule)
							.controlSize(.regular)
						}
					}
				}
				.padding(.all, 16)
				.background(colorScheme == .dark ? .black.opacity(0.85) : .white.opacity(0.85))
				.clipShape(
					RoundedRectangle(cornerRadius: 16)
				)

				Spacer()

				Button(action: {
					finish()
				}) {
					Text("Continue")
				}
				.buttonStyle(GrowingButton())
				.disabled(!hasPermissions)
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

	private func finish() {
		if !hasNotifications {
			UserDefaults.disableAllNotifications()
		}

		UserDefaults.onboardingDone = true
		UserDefaults.locationAuthSkipped = !hasLocation
		NotificationCenter.default.post(
			name: .onboardingDone,
			object: nil
		)

		done = true
	}
}

struct GrowingButton: ButtonStyle {
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding()
			.background(colorScheme == .dark ? .black : .white)
			.foregroundStyle(Color.accentColor)
			.clipShape(Capsule())
			.scaleEffect(configuration.isPressed ? 1.2 : 1)
			.animation(.easeOut(duration: 0.2), value: configuration.isPressed)
	}
}
