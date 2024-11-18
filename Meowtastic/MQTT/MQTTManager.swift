import CocoaMQTT
import Foundation
import OSLog

final class MQTTManager {
	var client: CocoaMQTT?
	var delegate: MQTTManagerDelegate?
	var topic: String?

	private var isDefaultConfig = false

	func connect(config: MQTTConfigEntity) {
		if isDefaultConfig {
			disconnect()
		}

		guard config.enabled else {
			Logger.mqtt.info("MQTT proxy is disabled, not connecting to MQTT broker")
			return
		}

		let host: String
		let useSsl = config.tlsEnabled == true
		var port = useSsl ? 8883 : 1883

		if let address = config.address, !address.isEmpty {
			if address.contains(":") {
				host = address.components(separatedBy: ":")[0]
				port = Int(address.components(separatedBy: ":")[1]) ?? (useSsl ? 8883 : 1883)
			}
			else {
				host = address
			}
		}
		else {
			host = "mqtt.meshtastic.org"
		}

		let minimumVersion = "2.3.2"
		let isSupportedVersion = [.orderedAscending, .orderedSame]
			.contains(minimumVersion.compare(UserDefaults.firmwareVersion, options: .numeric))

		let rootTopic: String
		if let root = config.root, !root.isEmpty {
			rootTopic = root
		}
		else {
			rootTopic = "msh"
		}

		connect(
			host: host,
			port: port,
			useSsl: useSsl,
			username: config.username,
			password: config.password,
			topic: rootTopic + (isSupportedVersion ? "/2/e" : "/2/c") + "/#"
		)
	}

	func connectDefaults() {
		if (client?.connState ?? .disconnected) != .disconnected {
			return
		}

		let region = Locale.current.region?.identifier ?? "DE"

		connect(
			host: "mqtt.meshtastic.org",
			port: 1883,
			useSsl: false,
			username: "meshdev",
			password: "large4cats",
			topic: "msh/\(region)/2/e/#",
			isDefaults: true
		)
	}

	// swiftlint:disable:next function_parameter_count
	private func connect(
		host: String,
		port: Int,
		useSsl: Bool,
		username: String?,
		password: String?,
		topic: String?,
		isDefaults: Bool = false
	) {
		guard !host.isEmpty else {
			delegate?.onMqttDisconnected()

			return
		}

		let client = CocoaMQTT(
			clientID: "MeowtasticMQTT_" + String(ProcessInfo().processIdentifier),
			host: host,
			port: UInt16(port)
		)

		client.delegate = self
		client.username = username
		client.password = password
		client.enableSSL = useSsl
		client.allowUntrustCACertificate = true
		client.autoReconnect = !isDefaults
		client.cleanSession = false // allow delivering old messages
		client.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
		client.logLevel = .warning

		if !client.connect() {
			delegate?.onMqttError(message: "MQTT connect error")
		}

		Logger.mqtt.debug("Connected & subscribed to \(String(describing: topic))")

		self.topic = topic
		self.client = client
		self.isDefaultConfig = isDefaults
	}

	func subscribe(topic: String, qos: CocoaMQTTQoS) {
		client?.subscribe(topic, qos: qos)
	}

	func unsubscribe(topic: String) {
		client?.unsubscribe(topic)
	}

	func publish(message: String, topic: String, qos: CocoaMQTTQoS) {
		client?.publish(topic, withString: message, qos: qos)
	}

	func disconnect() {
		client?.disconnect()
		client = nil
	}
}
