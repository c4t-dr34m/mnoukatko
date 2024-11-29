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

// Temporary (i fucking wish!) wrapper to separate whole observable BLEManager from one-direction actions (commands)
final class BLEActions: ObservableObject {
	private let bleManager: BLEManager

	init(bleManager: BLEManager) {
		self.bleManager = bleManager
	}

	@discardableResult
	func sendMessage(
		message: String,
		toUserNum: Int64,
		channel: Int32,
		isEmoji: Bool,
		replyID: Int64
	) -> Bool {
		bleManager.sendMessage(
			message: message,
			toUserNum: toUserNum,
			channel: channel,
			isEmoji: isEmoji,
			replyID: replyID
		)
	}

	@discardableResult
	func sendPosition(
		channel: Int32,
		destNum: Int64,
		wantResponse: Bool
	) -> Bool {
		bleManager.sendPosition(
			channel: channel,
			destNum: destNum,
			wantResponse: wantResponse
		)
	}

	@discardableResult
	func sendTraceRouteRequest(
		destNum: Int64,
		wantResponse: Bool
	) -> Bool {
		bleManager.sendTraceRouteRequest(
			destNum: destNum,
			wantResponse: wantResponse
		)
	}
}
