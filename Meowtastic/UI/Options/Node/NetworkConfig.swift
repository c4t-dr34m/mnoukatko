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
		ZStack {
			Form {
				if node.metadata?.hasWifi ?? false {
					Section(header: Text("WiFi")) {
						Toggle(isOn: $wifiEnabled) {
							Label("Enabled", systemImage: "wifi")
							Text("Enabling WiFi will disable the bluetooth connection to the app.")
						}
						.toggleStyle(SwitchToggleStyle(tint: .accentColor))

						HStack {
							Label("SSID", systemImage: "network")

							TextField("SSID", text: $wifiSsid)
								.foregroundColor(.gray)
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
							Label("Password", systemImage: "wallet.pass")
							TextField("Password", text: $wifiPsk)
								.foregroundColor(.gray)
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
							Label("Enabled", systemImage: "network")
							Text("Enabling Ethernet will disable the bluetooth connection to the app.")
						}
						.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					}
					.headerProminence(.increased)
				}
			}
			.disabled(connectedDevice.device == nil || node.networkConfig == nil)
			.scrollDismissesKeyboard(.interactively)

			SaveConfigButton(node: node, hasChanges: $hasChanges) {
				save()
			}
		}
		.navigationTitle("Network Config")
		.navigationBarItems(
			trailing: ConnectionInfo()
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
			var network = Config.NetworkConfig()
			network.wifiEnabled = self.wifiEnabled
			network.wifiSsid = self.wifiSsid
			network.wifiPsk = self.wifiPsk
			network.ethEnabled = self.ethEnabled
			// network.addressMode = Config.NetworkConfig.AddressMode.dhcp

			let adminIndex = connectedNode.myInfo?.adminIndex ?? 0
			if
				nodeConfig.saveNetworkConfig(
					config: network,
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
