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
import CoreData
import FirebaseAnalytics
import MeshtasticProtobufs
import SwiftUI

struct UserConfig: OptionsScreen {
	enum Field: Hashable {
		case frequencyOverride
	}

	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	private let floatFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		return formatter
	}()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@State
	private var isPresentingFactoryResetConfirm: Bool = false
	@State
	private var isPresentingSaveConfirm: Bool = false
	@State
	private var hasChanges = false
	@State
	private var shortName = ""
	@State
	private var longName: String = ""
	@State
	private var isLicensed = false
	@State
	private var overrideDutyCycle = false
	@State
	private var overrideFrequency: Float = 0.0
	@State
	private var txPower = 0
	@FocusState
	private var focusedField: Field?

	var body: some View {
		Form {
			Section(header: Text("User Details")) {
				VStack(alignment: .leading) {
					HStack {
						Text(isLicensed ? "Call sign" : "Long name")
							.font(.body)

						Spacer()

						TextField("", text: $longName)
							.optionsStyle()
							.onChange(of: longName) {
								if longName.utf8.count > (isLicensed ? 6 : 36) {
									longName = String(longName.dropLast())
								}
							}
					}
					.keyboardType(.default)
					.disableAutocorrection(true)

					if longName.isEmpty, isLicensed {
						Text("Call Sign must not be empty")
							.font(.body)
							.foregroundColor(.red)
					}

					Text("\(String(isLicensed ? "Call Sign" : "Long Name")) can be up to \(isLicensed ? "8" : "36") bytes long.")
						.foregroundColor(.gray)
						.font(.callout)

				}

				VStack(alignment: .leading) {
					HStack {
						Text("Short name")
							.font(.body)

						Spacer()

						TextField("", text: $shortName)
							.optionsStyle()
							.onChange(of: shortName) {
								if shortName.utf8.count > 4 {
									shortName = String(shortName.dropLast())
								}
							}
							.foregroundColor(.gray)
					}
					.keyboardType(.default)
					.disableAutocorrection(true)

					Text("The last 4 of the device MAC address will be appended to the short name to set the device's BLE Name.  Short name can be up to 4 bytes long.")
						.foregroundColor(.gray)
						.font(.callout)
				}

				// Only manage ham mode for the locally connected node
				if
					let device = connectedDevice.device,
					node.num > 0,
					node.num == device.num
				{
					Toggle(isOn: $isLicensed) {
						Text("Licensed operator")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					if isLicensed {
						Text("Onboarding for licensed operators requires firmware 2.0.20 or greater. Make sure to refer to your local regulations and contact the local amateur frequency coordinators with questions.")
							.font(.caption2)
						Text("What licensed operator mode does:\n* Sets the node name to your call sign \n* Broadcasts node info every 10 minutes \n* Overrides frequency, dutycycle and tx power \n* Disables encryption")
							.font(.caption2)

						HStack {
							Text("Frequency")
								.font(.body)

							Spacer()

							TextField(
								"Frequency override",
								value: $overrideFrequency,
								formatter: floatFormatter
							)
							.optionsStyle()
							.keyboardType(.decimalPad)
							.scrollDismissesKeyboard(.immediately)
							.focused($focusedField, equals: .frequencyOverride)
						}

						Stepper("\(txPower)dB transmit power", value: $txPower, in: 1...30, step: 1)
							.padding(5)
					}
				}
			}
			.headerProminence(.increased)
		}
		.disabled(connectedDevice.device == nil)
		.navigationTitle("User Config")
		.navigationBarItems(
			trailing: SaveButton(changes: $hasChanges) {
				save()
			}
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsUser.id, parameters: nil)
			setInitialValues()
		}
		.onChange(of: shortName) {
			hasChanges = true
		}
		.onChange(of: longName) {
			hasChanges = true
		}
		.onChange(of: overrideFrequency) {
			 hasChanges = true
		}
		.onChange(of: txPower) {
			hasChanges = true
		}
		.onChange(of: isLicensed) {
			if node.user?.longName?.count ?? 0 > 8 {
				longName = ""
			}

			hasChanges = true
		}
	}

	func setInitialValues() {
		shortName = node.user?.shortName ?? ""
		longName = node.user?.longName ?? ""
		isLicensed = node.user?.isLicensed ?? false
		txPower = Int(node.loRaConfig?.txPower ?? 0)
		overrideFrequency = node.loRaConfig?.overrideFrequency ?? 0.00

		hasChanges = false
	}

	func save() {
		if longName.isEmpty && isLicensed {
			return
		}

		let connectedUser = coreDataTools.getUser(
			id: connectedDevice.device?.num ?? -1,
			context: context
		)
		let connectedNode = coreDataTools.getNodeInfo(
			id: connectedDevice.device?.num ?? -1,
			context: context
		)

		if let connectedNode {
			if !isLicensed {
				var user = User()
				user.shortName = shortName
				user.longName = longName

				if
					nodeConfig.saveUser(
						config: user,
						fromUser: connectedUser,
						toUser: node.user!,
						adminIndex: connectedNode.myInfo?.adminIndex ?? 0
					) > 0
				{
					hasChanges = false
					goBack()
				}
			}
			else {
				var ham = HamParameters()
				ham.shortName = shortName
				ham.callSign = longName
				ham.txPower = Int32(txPower)
				ham.frequency = overrideFrequency

				if
					nodeConfig.saveLicensedUser(
						ham: ham,
						fromUser: connectedUser,
						toUser: node.user!,
						adminIndex: connectedNode.myInfo?.adminIndex ?? 0
					) > 0
				{
					hasChanges = false
					goBack()
				}
			}
		}
	}
}
