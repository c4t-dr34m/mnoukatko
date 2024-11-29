/*
Mňoukátko - the Meshtastic® client

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

protocol CommDelegate: AnyObject {
	func onTraceRouteReceived(for node: NodeInfoEntity?)
	func onNodeConfigReceived(_ type: ConfigType, num: Int64)
	func onNodeModuleConfigReceived(_ type: ConfigType, num: Int64)
	func onChannelInfoReceived(index: Int32, name: String?, num: Int64)
	func onMyInfoReceived(num: Int64)
	func onInfoReceived(num: Int64)
	func onMetadataReceived(num: Int64)
}
