/*
Mňoukátko - the Meshtastic® client

Copyright © 2021-2024 Garth Vander Houwen
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
import CocoaMQTT
import Foundation

extension MQTTManager: CocoaMQTTDelegate {
	func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		if ack == .accept {
			delegate?.onMqttConnected()
		}
		else {
			var errorDescription = "Unknown Error"

			switch ack {
			case .accept:
				errorDescription = "No Error"

			case .unacceptableProtocolVersion:
				errorDescription = "Unacceptable Protocol version"

			case .identifierRejected:
				errorDescription = "Invalid Id"

			case .serverUnavailable:
				errorDescription = "Invalid Server"

			case .badUsernameOrPassword:
				errorDescription = "Invalid Credentials"

			case .notAuthorized:
				errorDescription = "Authorization Error"

			default:
				errorDescription = "Unknown Error"
			}

			delegate?.onMqttError(message: errorDescription)

			disconnect()
		}
	}

	func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		if let error = err {
			delegate?.onMqttError(message: error.localizedDescription)
		}
		delegate?.onMqttDisconnected()
	}

	public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		delegate?.onMqttMessageReceived(message: message)
	}

	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		// no-op
	}

	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		// no-op
	}

	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
		// no-op
	}

	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
		// no-op
	}

	func mqttDidPing(_ mqtt: CocoaMQTT) {
		// no-op
	}

	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
		// no-op
	}
}
