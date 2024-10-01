import CoreData
import FirebaseAnalytics
import MapKit
import MeshtasticProtobufs
import OSLog
import SwiftUI

func generateChannelKey(size: Int) -> String {
	var keyData = Data(count: size)
	_ = keyData.withUnsafeMutableBytes {
		SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!)
	}

	return keyData.base64EncodedString()
}

struct Channels: View {
	var node: NodeInfoEntity
	
	@State
	var hasChanges = false
	@State
	var hasValidKey = true
	@State
	var isPresentingSaveConfirm: Bool = false
	@State
	var channelIndex: Int32 = 0
	@State
	var channelName = ""
	@State
	var channelKeySize = 16
	@State
	var channelKey = "AQ=="
	@State
	var channelRole = 0
	@State
	var uplink = false
	@State
	var downlink = false
	@State
	var positionPrecision = 32.0
	@State
	var preciseLocation = true
	@State
	var positionsEnabled = true
	@State
	var supportedVersion = true
	@State
	var selectedChannel: ChannelEntity?
	@State
	var minimumVersion = "2.2.24"
	
	@Environment(\.managedObjectContext)
	private var context
	@EnvironmentObject
	private var bleManager: BLEManager
	@EnvironmentObject
	private var nodeConfig: NodeConfig
	@Environment(\.dismiss)
	private var goBack
	@Environment(\.sizeCategory)
	private var sizeCategory
	
	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(key: "favorite", ascending: false),
			NSSortDescriptor(key: "lastHeard", ascending: false),
			NSSortDescriptor(key: "user.longName", ascending: true)
		],
		animation: .default
	)
	private var nodes: FetchedResults<NodeInfoEntity>
	private var nodeChannels: [ChannelEntity]? {
		guard let channels = node.myInfo?.channels else {
			return nil
		}

		return channels.array as? [ChannelEntity]
	}

	@ViewBuilder
	var body: some View {
		VStack {
			List {
				if let nodeChannels {
					ForEach(nodeChannels, id: \.index) { channel in
						Button(action: {
							channelIndex = channel.index
							channelRole = Int(channel.role)
							channelKey = channel.psk?.base64EncodedString() ?? ""

							if channelKey.count == 0 {
								channelKeySize = 0
							}
							else if channelKey == "AQ==" {
								channelKeySize = -1
							}
							else if channelKey.count == 4 {
								channelKeySize = 1
							}
							else if channelKey.count == 24 {
								channelKeySize = 16
							}
							else if channelKey.count == 32 {
								channelKeySize = 24
							}
							else if channelKey.count == 44 {
								channelKeySize = 32
							}

							channelName = channel.name ?? ""
							uplink = channel.uplinkEnabled
							downlink = channel.downlinkEnabled
							positionPrecision = Double(channel.positionPrecision)

							if !supportedVersion && channelRole == 1 {
								positionPrecision = 32
								preciseLocation = true
								positionsEnabled = true
							}
							else if !supportedVersion && channelRole == 2 {
								positionPrecision = 0
								preciseLocation = false
								positionsEnabled = false
							}
							else {
								if positionPrecision == 32 {
									preciseLocation = true
									positionsEnabled = true
								}
								else {
									preciseLocation = false
								}

								if positionPrecision == 0 {
									positionsEnabled = false
								}
								else {
									positionsEnabled = true
								}
							}
							hasChanges = false
							selectedChannel = channel
						}) {
							VStack(alignment: .leading) {
								HStack {
									AvatarAbstract(
										String(channel.index),
										size: 45
									)
									.padding(.trailing, 5)

									HStack {
										if channel.name?.isEmpty ?? false {
											if channel.role == 1 {
												Text(String("PrimaryChannel").camelCaseToWords())
													.font(.headline)
											}
											else {
												Text(String("Channel \(channel.index)").camelCaseToWords())
													.font(.headline)
											}
										}
										else {
											Text(String(channel.name ?? "Channel \(channel.index)").camelCaseToWords())
												.font(.headline)
										}
									}
								}
							}
						}
					}
				}
			}
			.sheet(item: $selectedChannel) { _ in
				ChannelForm(
					channelIndex: $channelIndex,
					channelName: $channelName,
					channelKeySize: $channelKeySize,
					channelKey: $channelKey,
					channelRole: $channelRole,
					uplink: $uplink,
					downlink: $downlink,
					positionPrecision: $positionPrecision,
					preciseLocation: $preciseLocation,
					positionsEnabled: $positionsEnabled,
					hasChanges: $hasChanges,
					hasValidKey: $hasValidKey,
					supportedVersion: $supportedVersion
				)
				.presentationDetents([.large])
				.presentationDragIndicator(.visible)
				.onAppear {
					supportedVersion = bleManager.connectedVersion == "0.0.0"
					|| [.orderedAscending, .orderedSame].contains(minimumVersion.compare(bleManager.connectedVersion, options: .numeric))
				}

				HStack {
					Button {
						var channel = Channel()
						channel.index = channelIndex
						channel.role = ChannelRoles(rawValue: channelRole)?.protoEnumValue() ?? .secondary
						channel.index = channelIndex
						channel.settings.name = channelName
						channel.settings.psk = Data(base64Encoded: channelKey) ?? Data()
						channel.settings.uplinkEnabled = uplink
						channel.settings.downlinkEnabled = downlink
						channel.settings.moduleSettings.positionPrecision = UInt32(positionPrecision)

						if let selectedChannel {
							selectedChannel.role = Int32(channelRole)
							selectedChannel.index = channelIndex
							selectedChannel.name = channelName
							selectedChannel.psk = Data(base64Encoded: channelKey) ?? Data()
							selectedChannel.uplinkEnabled = uplink
							selectedChannel.downlinkEnabled = downlink
							selectedChannel.positionPrecision = Int32(positionPrecision)
						}

						guard let mutableChannels = node.myInfo?.channels?.mutableCopy() as? NSMutableOrderedSet else {
							return
						}

						if mutableChannels.contains(selectedChannel as Any) {
							let replaceChannel = mutableChannels.first(
								where: {
									selectedChannel?.psk == ($0 as AnyObject).psk
									&& selectedChannel?.name == ($0 as AnyObject).name
								}
							)
							mutableChannels.replaceObject(
								at: mutableChannels.index(of: replaceChannel as Any),
								with: selectedChannel as Any
							)
						}
						else {
							mutableChannels.add(selectedChannel as Any)
						}

						node.myInfo?.channels = mutableChannels.copy() as? NSOrderedSet
						context.refresh(selectedChannel!, mergeChanges: true)

						if channel.role != Channel.Role.disabled {
							do {
								try context.save()
							}
							catch {
								context.rollback()
							}
						}
						else {
							let objects = selectedChannel?.allPrivateMessages ?? []

							for object in objects {
								context.delete(object)
							}

							for node in nodes where node.channel == channel.index {
								context.delete(node)
							}

							context.delete(selectedChannel!)

							do {
								try context.save()
							}
							catch {
								context.rollback()
							}
						}

						let adminMessageId = nodeConfig.saveChannel(
							channel: channel,
							fromUser: node.user!,
							toUser: node.user!
						)

						if adminMessageId > 0 {
							selectedChannel = nil
							channelName = ""
							channelRole	= 2
							hasChanges = false
						}
					} label: {
						Label("save", systemImage: "square.and.arrow.down")
					}
					.disabled(bleManager.getConnectedDevice() == nil || !hasChanges || !hasValidKey)
					.buttonStyle(.bordered)
					.buttonBorderShape(.capsule)
					.controlSize(.large)
					.padding(.bottom)
				}
			}

			if let nodeChannels, nodeChannels.count < 8 {
				Button {
					let channelIndexes = nodeChannels.compactMap { channel -> Int in
						(channel as AnyObject).index
					}
					let firstChannelIndex = firstMissingChannelIndex(channelIndexes)

					channelKeySize = 16
					channelName = ""
					channelIndex = Int32(firstChannelIndex)
					channelRole = 2
					channelKey = generateChannelKey(size: channelKeySize)
					positionsEnabled = false
					preciseLocation = false
					positionPrecision = 0
					uplink = false
					downlink = false
					hasChanges = true

					let newChannel = ChannelEntity(context: context)
					newChannel.id = channelIndex
					newChannel.index = channelIndex
					newChannel.uplinkEnabled = uplink
					newChannel.downlinkEnabled = downlink
					newChannel.name = channelName
					newChannel.role = Int32(channelRole)
					newChannel.psk = Data(base64Encoded: channelKey) ?? Data()
					newChannel.positionPrecision = Int32(positionPrecision)

					selectedChannel = newChannel
				} label: {
					Label(
						"Add Channel",
						systemImage: "plus.square"
					)
				}
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
				.controlSize(.large)
				.padding()
			}
		}
		.navigationTitle("Channels")
		.navigationBarItems(
			trailing: ConnectionInfo()
		)
		.onAppear {
			Analytics.logEvent(AnalyticEvents.optionsChannels.id, parameters: nil)
		}
	}

	private func firstMissingChannelIndex(_ indexes: [Int]) -> Int {
		let smallestIndex = 1
		if indexes.isEmpty {
			return smallestIndex
		}

		if smallestIndex <= indexes.count {
			for element in smallestIndex...indexes.count where !indexes.contains(element) {
				return element
			}
		}

		return indexes.count + 1
	}
}
