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

		if
			let connectedDevice = getConnectedDevice(),
			let binaryData: Data = try? toRadio.serializedData()
		{
			connectedDevice.peripheral.writeValue(
				binaryData,
				for: characteristicToRadio,
				type: .withResponse
			)

			Analytics.logEvent(
				AnalyticEvents.mqttMessage.id,
				parameters: [
					"topic": message.topic
				]
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
