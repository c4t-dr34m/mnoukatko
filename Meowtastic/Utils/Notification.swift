import Foundation

struct Notification {
	var id: String
	var title: String
	var subtitle: String
	var content: String
	var target: String?
	var path: String?

	init(
		id: String = UUID().uuidString,
		title: String,
		subtitle: String,
		content: String,
		target: String? = nil,
		path: String? = nil
	) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.content = content
		self.target = target
		self.path = path
	}
}
