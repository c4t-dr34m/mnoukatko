import Foundation

struct Notification {
	var id: String
	var title: String
	var subtitle: String?
	var body: String?
	var path: URL?

	init(
		id: String = UUID().uuidString,
		title: String,
		subtitle: String? = nil,
		body: String? = nil,
		path: URL? = nil
	) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.body = body
		self.path = path
	}
}
