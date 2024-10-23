import Foundation

protocol BLEDelegate: AnyObject {
	func onTraceRouteReceived(for node: NodeInfoEntity?)
	func onNodeConfigReceived(_ type: ConfigType, num: Int64)
	func onNodeModuleConfigReceived(_ type: ConfigType, num: Int64)
	func onChannelInfoReceived(index: Int32, name: String?, num: Int64)
	func onMyInfoReceived(num: Int64)
	func onInfoReceived(num: Int64)
	func onMetadataReceived(num: Int64)
}
