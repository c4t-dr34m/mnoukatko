import CoreData
import FirebaseAnalytics
import Foundation
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct SecurityConfig: OptionsScreen {
	var node: NodeInfoEntity
	var coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@State
	private var hasChanges = false
	@State
	private var publicKey = ""
	@State
	private var privateKey = ""
	@State
	private var adminKey = ""
	@State
	private var adminKey2 = ""
	@State
	private var adminKey3 = ""
	@State
	private var isManaged = false
	@State
	private var serialEnabled = false
	@State
	private var debugLogApiEnabled = false
	@State
	private var adminChannelEnabled = false

	@ViewBuilder
	var body: some View {
		ZStack {
			Form {
				Section(header: Text("Message Keys")) {
					VStack(alignment: .leading) {
						publicKeyEntry
						Divider()

						privateKeyEntry
						Divider()

						Label("Primary Admin Key", systemImage: "key.viewfinder")
						TextEntry($adminKey, monospaced: true, placeholder: "Primary Admin Key") { key in
							validate(key: key, allowEmpty: true)
						}
						Divider()

						Label("Secondary Admin Key", systemImage: "key.viewfinder")
						TextEntry($adminKey2, monospaced: true, placeholder: "Secondary Admin Key") { key in
							validate(key: key, allowEmpty: true)
						}
						Divider()

						Label("Tertiary Admin Key", systemImage: "key.viewfinder")
						TextEntry($adminKey3, monospaced: true, placeholder: "Tertiary Admin Key") { key in
							validate(key: key, allowEmpty: true)
						}
					}
				}
				.headerProminence(.increased)

				Section(header: Text("Logs")) {
					Toggle(isOn: $serialEnabled) {
						Label("Serial Console", systemImage: "terminal")
						Text("Serial Console over the Stream API.")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					Toggle(isOn: $debugLogApiEnabled) {
						Label("Debug Logs", systemImage: "ant.fill")
						Text("Output live debug logging over serial, view and export position-redacted device logs over Bluetooth.")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}
				.headerProminence(.increased)

				Section(header: Text("Administration")) {
					if adminKey.length > 0 || adminChannelEnabled {
						Toggle(isOn: $isManaged) {
							Label("Managed Device", systemImage: "gearshape.arrow.triangle.2.circlepath")
							Text("Device is managed by a mesh administrator, the user is unable to access any of the device settings.")
						}
						.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					}

					Toggle(isOn: $adminChannelEnabled) {
						Label("Legacy Administration", systemImage: "lock.slash")

						Text("Allow incoming device control over the insecure legacy admin channel.")
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}
				.headerProminence(.increased)
			}
			.disabled(connectedDevice.device == nil || node.networkConfig == nil)
			.scrollDismissesKeyboard(.immediately)

			SaveConfigButton(node: node, hasChanges: $hasChanges) {
				save()
			}
		}
		.navigationTitle("Network Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsSecurity.id, parameters: nil)
			setInitialValues()
		}
		.onChange(of: isManaged) {
			hasChanges = true
		}
		.onChange(of: serialEnabled) {
			hasChanges = true
		}
		.onChange(of: debugLogApiEnabled) {
			hasChanges = true
		}
		.onChange(of: adminChannelEnabled) {
			hasChanges = true
		}
		.onChange(of: publicKey) {
			hasChanges = true
		}
		.onChange(of: privateKey) {
			hasChanges = true
		}
		.onChange(of: adminKey) {
			hasChanges = true
		}
		.onChange(of: adminKey2) {
			hasChanges = true
		}
		.onChange(of: adminKey3) {
			hasChanges = true
		}
	}

	@ViewBuilder
	private var publicKeyEntry: some View {
		Label("Public Key", systemImage: "key")

		TextEntry($publicKey, monospaced: true, placeholder: "Public Key") { key in
			validate(key: key)
		}

		Text("Sent out to other nodes on the mesh to allow them to compute a shared secret key.")
			.foregroundStyle(.secondary)
			.font(.caption)
	}

	@ViewBuilder
	private var privateKeyEntry: some View {
		Label("Private Key", systemImage: "key.fill")

		TextEntry($privateKey, monospaced: true, placeholder: "Private Key") { key in
			validate(key: key)
		}

		Text("Used to create a shared key with a remote device.")
			.foregroundStyle(.secondary)
			.font(.caption)
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user,
			validateSession(for: node),
			node.securityConfig == nil
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			nodeConfig.requestSecurityConfig(fromUser: fromUser, toUser: toUser, adminIndex: adminIndex)
		}

		if let config = node.securityConfig {
			publicKey = config.publicKey?.base64EncodedString() ?? ""
			privateKey = config.privateKey?.base64EncodedString() ?? ""
			adminKey = config.adminKey?.base64EncodedString() ?? ""
			adminKey2 = config.adminKey?.base64EncodedString() ?? ""
			adminKey3 = config.adminKey?.base64EncodedString() ?? ""

			isManaged = config.isManaged
			serialEnabled = config.serialEnabled
			debugLogApiEnabled = config.debugLogApiEnabled
			adminChannelEnabled = config.adminChannelEnabled
		}
		else {
			publicKey = ""
			privateKey = ""
			adminKey = ""
			adminKey2 = ""
			adminKey3 = ""

			isManaged = false
			serialEnabled = false
			debugLogApiEnabled = false
			adminChannelEnabled = false
		}

		hasChanges = false
	}

	func save() {
		guard
			validate(key: publicKey)
				|| validate(key: privateKey)
				|| validate(key: adminKey, allowEmpty: true)
		else {
			return
		}

		guard
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		else {
			return
		}

		var security = Config.SecurityConfig()
		security.publicKey = Data(base64Encoded: publicKey) ?? Data()
		security.privateKey = Data(base64Encoded: privateKey) ?? Data()
		security.adminKey = [
			Data(base64Encoded: adminKey) ?? Data(),
			Data(base64Encoded: adminKey2) ?? Data(),
			Data(base64Encoded: adminKey3) ?? Data()
		]
		security.isManaged = isManaged
		security.serialEnabled = serialEnabled
		security.debugLogApiEnabled = debugLogApiEnabled
		security.adminChannelEnabled = adminChannelEnabled

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveSecurityConfig(
				config: security,
				fromUser: fromUser,
				toUser: toUser,
				adminIndex: adminIndex
			) > 0
		{
			hasChanges = false
			goBack()
		}
	}

	private func validate(key: String, allowEmpty: Bool = false) -> Bool {
		let keyData = Data(base64Encoded: key)
		if let keyData, keyData.count == 32 {
			return true
		}
		else if allowEmpty, key.isEmpty {
			return true
		}

		return false
	}
}
