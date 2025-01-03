/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen

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

enum Constants {
	/// `UInt32.max` or FFFF,FFFF in hex is used to identify messages that are being
	/// sent to a channel and are not a DM to an individual user. This is used
	/// in the `to` field of some mesh packets.
	static let maximumNodeNum = UInt32.max
	/// Based on the NUM_RESERVED from the firmware.
	/// https://github.com/meshtastic/firmware/blob/46d7b82ac1a4292ba52ca690e1a433d3a501a9e5/src/mesh/NodeDB.cpp#L522
	static let minimumNodeNum = 4
}
