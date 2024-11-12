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

	@ViewBuilder
	var body: some View {
		NavigationStack {
			Form {
				Section(header: Text("Details")) {
					HStack {
						Text("Name")

						Spacer()

						TextField(
							"Channel Name",
							text: $channelName
						)
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
						Picker("Key Size", selection: $channelKeySize) {
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

						TextField(
							"Key",
							text: $channelKey,
							axis: .vertical
						)
						.optionsStyle()
						.disableAutocorrection(true)
						.keyboardType(.alphabet)
						.textSelection(.enabled)
						.background(
							RoundedRectangle(cornerRadius: 10.0)
								.stroke(
									hasValidKey ? Color.clear : Color.red,
									lineWidth: 2.0
								)
						)
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
						.disabled(channelKeySize <= 0)
					}

					HStack {
						if channelRole == 1 {
							Picker("Channel Role", selection: $channelRole) {
								Text("Primary").tag(1)
							}
							.pickerStyle(.automatic)
							.disabled(true)
						}
						else {
							Text("Channel Role")

							Spacer()

							Picker("Channel Role", selection: $channelRole) {
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
							Label(
								channelRole == 1 ? "Positions Enabled" : "Allow Position Requests",
								systemImage: positionsEnabled ? "mappin" : "mappin.slash"
							)
						}
						.toggleStyle(SwitchToggleStyle(tint: .accentColor))
						.disabled(!supportedVersion)
					}

					if positionsEnabled {
						VStack(alignment: .leading) {
							Toggle(isOn: $preciseLocation) {
								Label("Precise Location", systemImage: "scope")
							}
							.toggleStyle(SwitchToggleStyle(tint: .accentColor))
							.disabled(!supportedVersion)
							.listRowSeparator(.visible)
							.onChange(of: preciseLocation) {
								if !preciseLocation {
									positionPrecision = 13
								}
							}
						}

						if !preciseLocation {
							VStack(alignment: .leading) {
								Label("Approximate Location", systemImage: "location.slash.circle.fill")

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
						Label("Uplink", systemImage: "arrowshape.up")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.listRowSeparator(.visible)

					Toggle(isOn: $downlink) {
						Label("Downlink", systemImage: "arrowshape.down")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.listRowSeparator(.visible)
				}
				.headerProminence(.increased)
			}
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
