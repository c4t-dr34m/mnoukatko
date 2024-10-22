import Foundation

struct Notification {
	var id: String
	var title: String
	var subtitle: String?
	var body: String?
	var target: String?
	var path: String?

	init(
		id: String = UUID().uuidString,
		title: String,
		subtitle: String? = nil,
		body: String? = nil,
		target: String? = nil,
		path: String? = nil
	) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.body = body
		self.target = target
		self.path = path
	}
}
