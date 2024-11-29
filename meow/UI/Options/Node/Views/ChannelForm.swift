/*
Meow - the Meshtastic® client

Copyright © 2022-2024 Garth Vander Houwen
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
import SwiftUI

struct ChannelForm: View {
	@Binding
	var channelIndex: Int32
	@Binding
	var channelName: String
	@Binding
	var channelKeySize: Int
	@Binding
	var channelKey: String
	@Binding
	var channelRole: Int
	@Binding
	var uplink: Bool
	@Binding
	var downlink: Bool
	@Binding
	var positionPrecision: Double
	@Binding
	var preciseLocation: Bool
	@Binding
	var positionsEnabled: Bool
	@Binding
	var hasChanges: Bool
	@Binding
	var hasValidKey: Bool
	@Binding
	var supportedVersion: Bool
	var onSave: (() -> Void)?

	@ViewBuilder
	var body: some View {
		NavigationStack {
			Form {
				Section(header: Text("Details")) {
					HStack {
						Text("Name")

						Spacer()

						TextField("", text: $channelName)
							.optionsStyle()
							.onChange(of: channelName) {
								channelName = channelName.replacing(" ", with: "")
								if channelName.utf8.count > 11 {
									channelName = String(channelName.dropLast())
								}

								hasChanges = true
							}
					}

					HStack {
						Picker("Key size", selection: $channelKeySize) {
							Text("Default").tag(-1)
							Text("Empty").tag(0)
							Text("1 byte").tag(1)
							Text("128 bit").tag(16)
							Text("256 bit").tag(32)
						}

						Spacer()

						Button {
							if channelKeySize == -1 {
								channelKey = "AQ=="
							}
							else {
								channelKey = generateChannelKey(size: channelKeySize)
							}
						} label: {
							Image(systemName: "lock.rotation")
								.font(.title)
						}
						.buttonStyle(.bordered)
						.buttonBorderShape(.capsule)
						.controlSize(.small)

					}

					HStack(alignment: .center) {
						Text("Key")

						Spacer()

						TextField("", text: $channelKey)
							.optionsStyle()
							.disableAutocorrection(true)
							.keyboardType(.alphabet)
							.textSelection(.enabled)
							.disabled(channelKeySize <= 0)
							.onChange(of: channelKey) {
								if
									let tempKey = Data(base64Encoded: channelKey),
									tempKey.count == channelKeySize || channelKeySize == -1
								{
									hasValidKey = true
								}
								else {
									hasValidKey = false
								}

								hasChanges = true
							}
					}

					HStack {
						if channelRole == 1 {
							Picker("Role", selection: $channelRole) {
								Text("Primary").tag(1)
							}
							.disabled(true)
						}
						else {
							Text("Role")

							Spacer()

							Picker("Role", selection: $channelRole) {
								Text("Disabled").tag(0)
								Text("Secondary").tag(2)
							}
							.pickerStyle(.segmented)
						}
					}
				}
				.headerProminence(.increased)

				Section(header: Text("Position")) {
					VStack(alignment: .leading) {
						Toggle(isOn: $positionsEnabled) {
							Text(channelRole == 1 ? "Enabled" : "Allow Position Requests")
								.font(.body)
						}
						.toggleStyle(SwitchToggleStyle(tint: .accentColor))
						.disabled(!supportedVersion)
					}

					if positionsEnabled {
						VStack(alignment: .leading) {
							Toggle(isOn: $preciseLocation) {
								Text("Precise")
									.font(.body)
							}
							.toggleStyle(SwitchToggleStyle(tint: .accentColor))
							.disabled(!supportedVersion)
							.onChange(of: preciseLocation) {
								if !preciseLocation {
									positionPrecision = 13
								}
							}
						}

						if !preciseLocation {
							VStack(alignment: .leading) {
								Text("Approximate")
									.font(.body)

								Slider(value: $positionPrecision, in: 10...19, step: 1) {

								} minimumValueLabel: {
									Image(systemName: "minus")
								} maximumValueLabel: {
									Image(systemName: "plus")
								}

								Text(PositionPrecision(rawValue: Int(positionPrecision))?.description ?? "")
									.foregroundColor(.gray)
									.font(.callout)
							}
						}
					}
				}
				.headerProminence(.increased)

				Section(header: Text("MQTT")) {
					Toggle(isOn: $uplink) {
						Text("Uplink")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					Toggle(isOn: $downlink) {
						Text("Downlink")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}
				.headerProminence(.increased)
			}
			.navigationTitle("Channel Config")
			.navigationBarItems(
				trailing: SaveButton(changes: .constant(true), willReboot: false) {
					onSave?()
				}
			)
			.onAppear {
				let tempKey = Data(base64Encoded: channelKey) ?? Data()
				if tempKey.count == channelKeySize || channelKeySize == -1 {
					hasValidKey = true
				}
				else {
					hasValidKey = false
				}
			}
			.onChange(of: channelKeySize) {
				if channelKeySize == -1 {
					channelKey = "AQ=="
				}
				else {
					let key = generateChannelKey(size: channelKeySize)
					channelKey = key
				}

				hasChanges = true
			}
			.onChange(of: preciseLocation) {
				if preciseLocation {
					positionPrecision = 32
				}
				else {
					positionPrecision = 14
				}

				hasChanges = true
			}
			.onChange(of: positionsEnabled) {
				if positionsEnabled {
					if positionPrecision == 0 {
						positionPrecision = 32
					}
				}
				else {
					positionPrecision = 0
				}

				hasChanges = true
			}
			.onChange(of: channelName) {
				hasChanges = true
			}
			.onChange(of: channelKey) {
				hasChanges = true
			}
			.onChange(of: channelRole) {
				hasChanges = true
			}
			.onChange(of: positionPrecision) {
				hasChanges = true
			}
			.onChange(of: uplink) {
				hasChanges = true
			}
			.onChange(of: downlink) {
				hasChanges = true
			}
		}
	}
}
