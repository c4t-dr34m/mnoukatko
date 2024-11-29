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
