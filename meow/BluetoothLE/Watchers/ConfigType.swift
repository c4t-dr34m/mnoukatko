enum ConfigType: String {
	// node
	case bluetooth
	case device
	case display
	case lora = "LoRa"
	case network
	case position
	case power

	// node module
	case ambientLighting = "ambient lightning"
	case cannedMessage = "canned message"
	case detectionSensor = "detection sensor"
	case externalNotification = "ext. notification"
	case mqtt = "MQTT"
	case paxCounter = "PAX counter"
	case rangeTest = "range test"
	case serial
	case telemetry
	case storeForward = "store & forward"
}
