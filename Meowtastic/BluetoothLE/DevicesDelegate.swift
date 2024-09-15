import Foundation

protocol DevicesDelegate: AnyObject {
	func onChange(devices: [Device])
	func onDeviceConnected(name: String?)
	func onWantConfigFinished()
}
