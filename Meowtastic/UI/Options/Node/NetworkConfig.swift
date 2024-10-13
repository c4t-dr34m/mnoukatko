//
//  NetworkConfig.swift
//  Meshtastic
//
//  Copyright (c) Garth Vander Houwen 8/1/2022
//
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct NetworkConfig: View {
	private let coreDataTools = CoreDataTools()

	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack

	var node: NodeInfoEntity

	@State var hasChanges: Bool = false
	@State var wifiEnabled = false
	@State var wifiSsid = ""
	@State var wifiPsk = ""
	@State var wifiMode = 0
	@State var ntpServer = ""
	@State var ethEnabled = false
	@State var ethMode = 0

	var body: some View {
		VStack {
			Form {
				ConfigHeader(title: "Network", config: \.networkConfig, node: node)

				if node.metadata?.hasWifi ?? false {
					Section(header: Text("WiFi Options")) {

						Toggle(isOn: $wifiEnabled) {
							Label("enabled", systemImage: "wifi")
							Text("Enabling WiFi will disable the bluetooth connection to the app.")
						}
						.toggleStyle(SwitchToggleStyle(tint: .meowOrange))

						HStack {
							Label("ssid", systemImage: "network")
							TextField("ssid", text: $wifiSsid)
								.foregroundColor(.gray)
								.autocapitalization(.none)
								.disableAutocorrection(true)
								.onChange(of: wifiSsid, perform: { _ in
									let totalBytes = wifiSsid.utf8.count
									// Only mess with the value if it is too big
									if totalBytes > 32 {
										wifiSsid = String(wifiSsid.dropLast())
									}
									hasChanges = true
								})
								.foregroundColor(.gray)
						}
						.keyboardType(.default)
						HStack {
							Label("password", systemImage: "wallet.pass")
							TextField("password", text: $wifiPsk)
								.foregroundColor(.gray)
								.autocapitalization(.none)
								.disableAutocorrection(true)
								.onChange(of: wifiPsk, perform: { _ in
									let totalBytes = wifiPsk.utf8.count
									// Only mess with the value if it is too big
									if totalBytes > 63 {
										wifiPsk = String(wifiPsk.dropLast())
									}
									hasChanges = true
								})
								.foregroundColor(.gray)
						}
						.keyboardType(.default)
					}
				}

				if node.metadata?.hasEthernet ?? false {
					Section(header: Text("Ethernet Options")) {
						Toggle(isOn: $ethEnabled) {
							Label("enabled", systemImage: "network")
							Text("Enabling Ethernet will disable the bluetooth connection to the app.")
						}
						.toggleStyle(SwitchToggleStyle(tint: .meowOrange))
					}
				}
			}
			.scrollDismissesKeyboard(.interactively)
			.disabled(connectedDevice.device == nil || node.networkConfig == nil)

			SaveConfigButton(node: node, hasChanges: $hasChanges) {
				if
					let device = connectedDevice.device,
					let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context)
				{
					var network = Config.NetworkConfig()
					network.wifiEnabled = self.wifiEnabled
					network.wifiSsid = self.wifiSsid
					network.wifiPsk = self.wifiPsk
					network.ethEnabled = self.ethEnabled
					// network.addressMode = Config.NetworkConfig.AddressMode.dhcp

					let adminMessageId = nodeConfig.saveNetworkConfig(
						config: network,
						fromUser: connectedNode.user!,
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
		.navigationTitle("Network Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsNetwork.id, parameters: nil)

			setNetworkValues()

			// Need to request a NetworkConfig from the remote node before allowing changes
			if let device = connectedDevice.device, node.networkConfig == nil {
				Logger.mesh.info("empty network config")

				if let connectedNode = coreDataTools.getNodeInfo(id: device.num, context: context) {
					nodeConfig.requestNetworkConfig(
						fromUser: connectedNode.user!,
						toUser: node.user!,
						adminIndex: connectedNode.myInfo?.adminIndex ?? 0
					)
				}
			}
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

	private func setNetworkValues() {
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
}
