import CoreBluetooth

extension CBManagerState {
	var name: String {
		switch self {
		case .unknown:
			return "Unknown"

		case .resetting:
			return "Resetting"
		case .unsupported:
			return "Unsupported"

		case .unauthorized:
			return "Unauthorized"

		case .poweredOff:
			return "Powered Off"

		case .poweredOn:
			return "Powered On"

		default:
			return "Unwknow state: \(self.rawValue)"
		}
	}
}
