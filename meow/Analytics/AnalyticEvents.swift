/*
Meow - the Meshtastic® client

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
import Foundation

enum AnalyticEvents: String {
	// MARK: - app
	case appLaunch

	// MARK: - screens
	case connect
	case meshMap
	case messages
	case messageList
	case nodeDetail
	case nodeList
	case nodeMap
	case nodeRetrievalFailure
	case options
	case optionsAbout
	case optionsAppSettings
	case optionsChannels
	case optionsUser
	case optionsMQTT
	case optionsBluetooth
	case optionsDevice
	case optionsDisplay
	case optionsLoRa
	case optionsPosition
	case optionsNetwork
	case optionsPower
	case optionsSecurity
	case optionsTelemetry
	case traceRoute

	// MARK: - events
	case backgroundUpdate
	case backgroundDeviceConnected
	case backgroundWantConfig
	case backgroundFinished
	case ble
	case bleTimeout
	case bleCancelConnecting
	case bleConnect
	case bleDisconnect
	case bleTraceRoute
	case mqttConnect
	case mqttDisconnect
	case mqttMessage
	case mqttError

	enum BLERequest: String {
		case bluetoothConfig
		case bluetoothConfigSave
		case cannedMessages
		case channel
		case channelSave
		case deviceConfig
		case deviceConfigSave
		case deviceMetadata
		case displayConfig
		case displayConfigSave
		case factoryReset
		case favoriteNodeSet
		case favoriteNodeRemove
		case fixedPositionRemove
		case fixedPositionSet
		case licensedUserSave
		case loraConfig
		case loraConfigSave
		case message
		case mqttConfig
		case mqttConfigSave
		case nodeRemove
		case networkConfig
		case networkConfigSave
		case position
		case positionConfig
		case positionConfigSave
		case powerConfig
		case powerConfigSave
		case reboot
		case rebootOTA
		case resetDB
		case securityConfig
		case securityConfigSave
		case shutdown
		case userSave
		case wantConfig
		case wantConfigComplete
	}

	// MARK: - operation status
	enum OperationStatus {
		case success
		case error(String)
		case failureProcess
		case failureSend

		var description: String {
			switch self {
			case .success:
				return "success"

			case let .error(error):
				return "error_" + error

			case .failureProcess:
				return "failure_process"

			case .failureSend:
				return "failure_send"
			}
		}
	}

	// MARK: - supporting stuff
	var id: String {
		self.rawValue
	}

	static func trackBLEEvent(
		for operation: BLERequest,
		status: OperationStatus
	) {
		Analytics.logEvent(
			AnalyticEvents.ble.id,
			parameters: [
				operation.rawValue: status.description
			]
		)
	}

	static func getParams(
		for node: NodeInfoEntity,
		_ additionalParams: [String: Any]? = nil
	) -> [String: Any] {
		var params = [String: Any]()

		params["id"] = node.num

		if let shortName = node.user?.shortName {
			params["shortName"] = shortName
		}
		else {
			params["shortName"] = "N/A"
		}

		if let longName = node.user?.longName {
			params["longName"] = longName
		}
		else {
			params["longName"] = "N/A"
		}

		if let additionalParams {
			for (key, value) in additionalParams {
				params[key] = value
			}
		}

		return params
	}
}
