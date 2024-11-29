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
import FirebaseAnalytics
import OSLog
import SwiftUI

struct Options: View {
	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var connectedDevice: CurrentDevice
	@State
	private var connectedNodeNum: Int = 0
	@State
	private var preferredNodeNum: Int = 0

	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(key: "favorite", ascending: false),
			NSSortDescriptor(key: "user.longName", ascending: true)
		],
		animation: .default
	)
	private var nodes: FetchedResults<NodeInfoEntity>

	private var nodeSelected: NodeInfoEntity? {
		nodes.first(where: { node in
			node.num == connectedNodeNum
		})
	}

	private var nodeConnected: NodeInfoEntity? {
		nodes.first(where: { node in
			node.num == preferredNodeNum
		})
	}

	private var nodeIsConnected: Bool {
		connectedNodeNum > 0 && connectedNodeNum != preferredNodeNum
	}

	private var nodeHasAdmin: Bool {
		guard let myInfo = nodeConnected?.myInfo else {
			return false
		}

		return myInfo.adminIndex > 0
	}

	private var nodeIsManaged: Bool {
		guard let config = nodeConnected?.deviceConfig else {
			return false
		}

		return config.isManaged
	}

	@ViewBuilder
	var body: some View {
		NavigationStack {
			List {
				connection

				if !nodeIsManaged {
					nodeConfig
				}

				appConfig
			}
			.listStyle(.insetGrouped)
			.onChange(of: UserDefaults.preferredPeripheralNum, initial: true) {
				preferredNodeNum = UserDefaults.preferredPeripheralNum

				if !nodes.isEmpty {
					if connectedNodeNum == 0 {
						connectedNodeNum = Int(connectedDevice.getConnectedDevice() != nil ? preferredNodeNum : 0)
					}
				}
				else {
					connectedNodeNum = Int(connectedDevice.getConnectedDevice() != nil ? preferredNodeNum : 0)
				}
			}
			.navigationTitle("Options")
			.navigationBarItems(
				trailing: ConnectionInfo()
			)
		}
		.onAppear {
			Analytics.logEvent(AnalyticEvents.options.id, parameters: nil)
		}
	}

	@ViewBuilder
	private var connection: some View {
		NavigationLink {
			NavigationLazyView(
				Connect(node: nodeSelected)
			)
		} label: {
			Label {
				Text("Connection")
			} icon: {
				if nodeSelected != nil {
					Image(systemName: "wifi")
				}
				else {
					Image(systemName: "wifi.slash")
				}
			}
		}
	}

	@ViewBuilder
	private var nodeConfig: some View {
		if let nodeSelected {
			Section(
				header: Text("Node").fontDesign(.rounded)
			) {
				NavigationLink {
					NavigationLazyView(
						LoRaConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("LoRa")
					} icon: {
						Image(systemName: "wifi.circle")
					}
				}

				NavigationLink {
					NavigationLazyView(
						Channels(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Channels")
					} icon: {
						Image(systemName: "bubble.left.and.bubble.right")
					}
				}
				.disabled(nodeIsConnected)

				NavigationLink {
					NavigationLazyView(
						UserConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("User")
					} icon: {
						Image(systemName: "person.text.rectangle")
					}
				}

				NavigationLink {
					NavigationLazyView(
						DeviceConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Device")
					} icon: {
						Image(systemName: "flipphone")
					}
				}

				// TODO: add version check; this requires 2.5+
				NavigationLink {
					NavigationLazyView(
						SecurityConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Security")
					} icon: {
						Image(systemName: "lock")
					}
				}

				NavigationLink {
					NavigationLazyView(
						MQTTConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("MQTT")
					} icon: {
						Image(systemName: "network")
					}
				}

				NavigationLink {
					NavigationLazyView(
						BluetoothConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Bluetooth")
					} icon: {
						Image(systemName: "iphone.gen3")
					}
				}

				NavigationLink {
					NavigationLazyView(
						NetworkConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Network")
					} icon: {
						Image(systemName: "wifi.router")
					}
				}

				NavigationLink {
					NavigationLazyView(
						PositionConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("GPS")
					} icon: {
						Image(systemName: "mappin.and.ellipse")
					}
				}

				NavigationLink {
					NavigationLazyView(
						TelemetryConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Telemetry")
					} icon: {
						Image(systemName: "thermometer.medium")
					}
				}

				NavigationLink {
					NavigationLazyView(
						DisplayConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Display")
					} icon: {
						Image(systemName: "display")
					}
				}

				NavigationLink {
					NavigationLazyView(
						PowerConfig(node: nodeSelected)
					)
				} label: {
					Label {
						Text("Power")
					} icon: {
						Image(systemName: "powercord")
					}
				}
			}
			.headerProminence(.increased)
		}
	}

	@ViewBuilder
	private var appConfig: some View {
		Section(
			header: Text("Application").fontDesign(.rounded)
		) {
			NavigationLink {
				NavigationLazyView(
					AppSettings()
				)
			} label: {
				Label {
					Text("Settings")
				} icon: {
					Image(systemName: "gearshape")
				}
			}

			NavigationLink {
				NavigationLazyView(
					About()
				)
			} label: {
				Label {
					Text("About")
				} icon: {
					Image(systemName: "info")
				}
			}
		}
		.headerProminence(.increased)
	}
}
