import CoreData
import FirebaseAnalytics
import MeshtasticProtobufs
import SwiftUI

struct UserConfig: View {
	enum Field: Hashable {
		case frequencyOverride
	}

	private let coreDataTools = CoreDataTools()

	var node: NodeInfoEntity

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack

	@State private var isPresentingFactoryResetConfirm: Bool = false
	@State private var isPresentingSaveConfirm: Bool = false
	@State var hasChanges = false
	@State var shortName = ""
	@State var longName: String = ""
	@State var isLicensed = false
	@State var overrideDutyCycle = false
	@State var overrideFrequency: Float = 0.0
	@State var txPower = 0

	@FocusState var focusedField: Field?

	let floatFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		return formatter
	}()

	var body: some View {
		VStack {
			Form {
				Section(header: Text("User Details")) {
					VStack(alignment: .leading) {
						HStack {
							Label(isLicensed ? "Call Sign" : "Long Name", systemImage: "person.crop.rectangle.fill")

							TextField("Long Name", text: $longName)
								.onChange(of: longName, perform: { _ in
									let totalBytes = longName.utf8.count
									// Only mess with the value if it is too big
									if totalBytes > (isLicensed ? 6 : 36) {
										longName = String(longName.dropLast())
									}
								})
						}
						.keyboardType(.default)
						.disableAutocorrection(true)

						if longName.isEmpty && isLicensed {
							Label("Call Sign must not be empty", systemImage: "exclamationmark.square")
								.foregroundColor(.red)
						}

						Text("\(String(isLicensed ? "Call Sign" : "Long Name")) can be up to \(isLicensed ? "8" : "36") bytes long.")
							.foregroundColor(.gray)
							.font(.callout)

					}

					VStack(alignment: .leading) {
						HStack {
							Label("Short Name", systemImage: "circlebadge.fill")
							TextField("Short Name", text: $shortName)
								.foregroundColor(.gray)
								.onChange(of: shortName, perform: { _ in
									let totalBytes = shortName.utf8.count
									// Only mess with the value if it is too big
									if totalBytes > 4 {
										shortName = String(shortName.dropLast())
									}
								})
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
							Label("Licensed Operator", systemImage: "person.text.rectangle")
						}
						.toggleStyle(SwitchToggleStyle(tint: .accentColor))

						if isLicensed {
							Text("Onboarding for licensed operators requires firmware 2.0.20 or greater. Make sure to refer to your local regulations and contact the local amateur frequency coordinators with questions.")
								.font(.caption2)
							Text("What licensed operator mode does:\n* Sets the node name to your call sign \n* Broadcasts node info every 10 minutes \n* Overrides frequency, dutycycle and tx power \n* Disables encryption")
								.font(.caption2)

							HStack {
								Label("Frequency", systemImage: "waveform.path.ecg")
								Spacer()
								TextField("Frequency Override", value: $overrideFrequency, formatter: floatFormatter)
									.toolbar {
										ToolbarItemGroup(placement: .keyboard) {
											Button("dismiss.keyboard") {
												focusedField = nil
											}
											.font(.subheadline)
										}
									}
									.keyboardType(.decimalPad)
									.scrollDismissesKeyboard(.immediately)
									.focused($focusedField, equals: .frequencyOverride)
							}
							HStack {
								Image(systemName: "antenna.radiowaves.left.and.right")
									.foregroundColor(.accentColor)
								Stepper("\(txPower)db Transmit Power", value: $txPower, in: 1...30, step: 1)
									.padding(5)
							}
						}
					}
				}
			}
			.disabled(connectedDevice.device == nil)

			HStack {
				Button {
					isPresentingSaveConfirm = true
				} label: {
					Label("save", systemImage: "square.and.arrow.down")
				}
				.disabled(connectedDevice.device == nil || !hasChanges)
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
				.controlSize(.large)
				.padding()
				.confirmationDialog(
					"are.you.sure",
					isPresented: $isPresentingSaveConfirm,
					titleVisibility: .visible
				) {
					Button("Save User Config to \(node.user?.longName ?? "Unknown node")?") {
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
								var u = User()
								u.shortName = shortName
								u.longName = longName
								let adminMessageId = nodeConfig.saveUser(
									config: u,
									fromUser: connectedUser,
									toUser: node.user!,
									adminIndex: connectedNode.myInfo?.adminIndex ?? 0
								)

								if adminMessageId > 0 {
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

								let adminMessageId = nodeConfig.saveLicensedUser(
									ham: ham,
									fromUser: connectedUser,
									toUser: node.user!,
									adminIndex: connectedNode.myInfo?.adminIndex ?? 0
								)

								if adminMessageId > 0 {
									hasChanges = false
									goBack()
								}
							}
						}
					}
				} message: {
					Text("config.save.confirm")
				}
			}
			Spacer()
		}
		.navigationTitle("User Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsUser.id, parameters: nil)

			shortName = node.user?.shortName ?? ""
			longName = node.user?.longName ?? ""
			isLicensed = node.user?.isLicensed ?? false
			txPower = Int(node.loRaConfig?.txPower ?? 0)
			overrideFrequency = node.loRaConfig?.overrideFrequency ?? 0.00

			hasChanges = false
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
}
