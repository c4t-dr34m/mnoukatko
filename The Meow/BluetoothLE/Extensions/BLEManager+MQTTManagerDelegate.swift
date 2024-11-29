/*
The Meow - the Meshtastic® client

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
import CocoaMQTT
import CoreBluetooth
import FirebaseAnalytics
import MeshtasticProtobufs
import OSLog

extension BLEManager: MQTTManagerDelegate {
	func onMqttConnected() {
		guard
			let manager = mqttManager,
			let topic = manager.topic,
			let client = manager.client,
			client.connState == .connected
		else {
			return
		}

		mqttError = ""
		mqttConnected = true

		client.subscribe(topic)

		Logger.mqtt.info("Connected")

		Analytics.logEvent(
			AnalyticEvents.mqttConnect.id,
			parameters: [
				"topic": topic
			]
		)
	}

	func onMqttDisconnected() {
		mqttConnected = false

		Logger.mqtt.info("Disconnected")

		Analytics.logEvent(AnalyticEvents.mqttDisconnect.id, parameters: nil)
	}

	func onMqttMessageReceived(message: CocoaMQTTMessage) {
		guard !message.topic.contains("/stat/") else {
			return
		}

		var proxyMessage = MqttClientProxyMessage()
		proxyMessage.topic = message.topic
		proxyMessage.data = Data(message.payload)
		proxyMessage.retained = message.retained

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.mqttClientProxyMessage = proxyMessage

		guard let binaryData = try? toRadio.serializedData() else {
			return
		}

		Analytics.logEvent(
			AnalyticEvents.mqttMessage.id,
			parameters: [
				"topic": message.topic
			]
		)

		if canHaveDemo() {
			Logger.mqtt.debug("Received MQTT message in demo mode, trying to process")

			processRadioData(value: binaryData)
		}
		else if let connectedDevice = getConnectedDevice() {
			Logger.mqtt.debug("Received MQTT message, sending to radio")

			connectedDevice.peripheral.writeValue(
				binaryData,
				for: characteristicToRadio,
				type: .withResponse
			)
		}
	}

	func onMqttError(message: String) {
		mqttConnected = false
		mqttError = message

		Logger.mqtt.info("Error occured: \(message)")

		Analytics.logEvent(
			AnalyticEvents.mqttError.id,
			parameters: [
				"error": message
			]
		)
	}
}
