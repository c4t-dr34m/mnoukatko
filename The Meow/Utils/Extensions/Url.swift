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
import OSLog

extension URL {

	func regularFileAllocatedSize() throws -> UInt64 {
		let resourceValues = try self.resourceValues(forKeys: allocatedSizeResourceKeys)

		guard resourceValues.isRegularFile ?? false else {
			return 0
		}
		return UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
	}
	subscript(queryParam: String) -> String? {
		guard let url = URLComponents(string: self.absoluteString) else { return nil }
		if let parameters = url.queryItems {
			return parameters.first(where: { $0.name == queryParam })?.value
		} else if let paramPairs = url.fragment?.components(separatedBy: "?").last?.components(separatedBy: "&") {
			for pair in paramPairs where pair.contains(queryParam) {
				return pair.components(separatedBy: "=").last
			}
			return nil
		} else {
			return nil
		}
	}
	var attributes: [FileAttributeKey: Any]? {
		do {
			return try FileManager.default.attributesOfItem(atPath: path)
		} catch let error as NSError {
			Logger.services.error("FileAttribute error: \(error, privacy: . public)")
		}
		return nil
	}

	var fileSize: UInt64 {
		return attributes?[.size] as? UInt64 ?? UInt64(0)
	}

	var fileSizeString: String {
		return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
	}

	var creationDate: Date? {
		return attributes?[.creationDate] as? Date
	}
}
