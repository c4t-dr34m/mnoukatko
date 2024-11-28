enum KeyMatch: Int16 {
	case notSet = 0
	case notMatching = 1
	case matching = 2
	
	static func fromInt(_ value: Int16) -> KeyMatch {
		return KeyMatch(rawValue: value) ?? .notSet
	}
}
