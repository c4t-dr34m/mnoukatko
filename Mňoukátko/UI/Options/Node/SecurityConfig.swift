/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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
		Form {
			Section(header: Text("Message Keys")) {
				HStack {
					Text("Public")
						.font(.body)

					Spacer()

					KeyField($publicKey, monospaced: true) { key in
						validate(key: key)
					}
				}

				HStack {
					Text("Private")
						.font(.body)

					Spacer()

					KeyField($privateKey, monospaced: true) { key in
						validate(key: key)
					}
				}
			}

			Section(header: Text("Admin Keys")) {
				HStack {
					Text("Primary")
						.font(.body)

					Spacer()

					KeyField($adminKey, monospaced: true) { key in
						validate(key: key, allowEmpty: true)
					}
				}

				HStack {
					Text("Secondary")
						.font(.body)

					Spacer()

					KeyField($adminKey2, monospaced: true) { key in
						validate(key: key, allowEmpty: true)
					}
				}

				HStack {
					Text("Tertiary")
						.font(.body)

					Spacer()

					KeyField($adminKey3, monospaced: true) { key in
						validate(key: key, allowEmpty: true)
					}
				}
			}
			.headerProminence(.increased)

			Section(header: Text("Serial Console")) {
				Toggle(isOn: $serialEnabled) {
					Text("Serial console")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $debugLogApiEnabled) {
					Text("Logging")
						.font(.body)
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
			.headerProminence(.increased)

			Section(header: Text("Administration")) {
				if adminKey.count > 0 || adminChannelEnabled {
					Toggle(isOn: $isManaged) {
						Text("Managed device")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}

				Toggle(isOn: $adminChannelEnabled) {
					Text("Legacy administration")
						.font(.body)

					Text("Allow incoming device control over the insecure legacy admin channel.")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
			.headerProminence(.increased)
		}
		.disabled(connectedDevice.device == nil || node.networkConfig == nil)
		.scrollDismissesKeyboard(.interactively)
		.navigationTitle("Network Config")
		.navigationBarItems(
			trailing: SaveButton(changes: $hasChanges) {
				save()
			}
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
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		else {
			return
		}

		var config = Config.SecurityConfig()
		config.publicKey = Data(base64Encoded: publicKey) ?? Data()
		config.privateKey = Data(base64Encoded: privateKey) ?? Data()
		config.adminKey = [
			Data(base64Encoded: adminKey) ?? Data(),
			Data(base64Encoded: adminKey2) ?? Data(),
			Data(base64Encoded: adminKey3) ?? Data()
		]
		config.isManaged = isManaged
		config.serialEnabled = serialEnabled
		config.debugLogApiEnabled = debugLogApiEnabled
		config.adminChannelEnabled = adminChannelEnabled

		let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
		if
			nodeConfig.saveSecurityConfig(
				config: config,
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
		if let keyData, keyData.count == 32 || allowEmpty, key.isEmpty {
			return true
		}

		return false
	}
}
