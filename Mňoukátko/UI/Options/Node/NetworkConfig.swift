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
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct NetworkConfig: OptionsScreen {
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
	private var hasChanges: Bool = false
	@State
	private var wifiEnabled = false
	@State
	private var wifiSsid = ""
	@State
	private var wifiPsk = ""
	@State
	private var wifiMode = 0
	@State
	private var ntpServer = ""
	@State
	private var ethEnabled = false
	@State
	private var ethMode = 0

	@ViewBuilder
	var body: some View {
		Form {
			if node.metadata?.hasWifi ?? false {
				Section(header: Text("WiFi")) {
					Toggle(isOn: $wifiEnabled) {
						Text("WiFi")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))

					HStack {
						Text("SSID")
							.font(.body)

						Spacer()

						TextField("", text: $wifiSsid)
							.optionsStyle()
							.keyboardType(.default)
							.autocapitalization(.none)
							.disableAutocorrection(true)
							.onChange(of: wifiSsid) {
								let totalBytes = wifiSsid.utf8.count
								// Only mess with the value if it is too big
								if totalBytes > 32 {
									wifiSsid = String(wifiSsid.dropLast())
								}
								hasChanges = true
							}
					}

					HStack {
						Text("Password")
							.font(.body)

						Spacer()

						TextField("", text: $wifiPsk)
							.optionsStyle()
							.keyboardType(.default)
							.autocapitalization(.none)
							.disableAutocorrection(true)
							.onChange(of: wifiPsk) {
								let totalBytes = wifiPsk.utf8.count
								// Only mess with the value if it is too big
								if totalBytes > 63 {
									wifiPsk = String(wifiPsk.dropLast())
								}
								hasChanges = true
							}
					}
				}
				.headerProminence(.increased)
			}

			if let metadata = node.metadata, metadata.hasEthernet {
				Section(header: Text("Ethernet")) {
					Toggle(isOn: $ethEnabled) {
						Text("Enabled")
							.font(.body)
					}
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				}
				.headerProminence(.increased)
			}
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
			Analytics.logEvent(AnalyticEvents.optionsNetwork.id, parameters: nil)
			setInitialValues()
		}
		.onChange(of: wifiEnabled) {
			hasChanges = true
		}
		.onChange(of: wifiSsid) {
			hasChanges = true
		}
		.onChange(of: wifiPsk) {
			hasChanges = true
		}
		.onChange(of: wifiMode) {
			hasChanges = true
		}
		.onChange(of: ethEnabled) {
			hasChanges = true
		}
	}

	func setInitialValues() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		{
			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0

			nodeConfig.requestNetworkConfig(
				fromUser: fromUser,
				toUser: toUser,
				adminIndex: adminIndex
			)
		}

		if let config = node.networkConfig {
			wifiEnabled = config.wifiEnabled
			wifiSsid = config.wifiSsid ?? ""
			wifiPsk = config.wifiPsk ?? ""
			wifiMode = Int(config.wifiMode)
			ethEnabled = config.ethEnabled
		}
		else {
			wifiEnabled = false
			wifiSsid = ""
			wifiPsk = ""
			wifiMode = 0
			ethEnabled = false
		}

		hasChanges = false
	}

	func save() {
		if
			let device = connectedDevice.device,
			let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context),
			let fromUser = connectedNode.user,
			let toUser = node.user
		{
			var config = Config.NetworkConfig()
			config.wifiEnabled = self.wifiEnabled
			config.wifiSsid = self.wifiSsid
			config.wifiPsk = self.wifiPsk
			config.ethEnabled = self.ethEnabled
			// network.addressMode = Config.NetworkConfig.AddressMode.dhcp

			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			if
				nodeConfig.saveNetworkConfig(
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
	}
}
