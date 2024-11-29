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
import CoreBluetooth

enum BluetoothUUID {
	static let meshtasticService = CBUUID(string: "0x6BA1B218-15A8-461F-9FA8-5DCAE273EAFD")
	static let toRadio = CBUUID(string: "0xF75C76D2-129E-4DAD-A1DD-7866124401E7")
	static let fromRadio = CBUUID(string: "0x2C55E69E-4993-11ED-B878-0242AC120002")
	static let fromRadioEOL = CBUUID(string: "0x8BA2BCC2-EE02-4A55-A531-C525C5E454D5")
	static let fromNum = CBUUID(string: "0xED9DA18C-A800-4F66-A670-AA7547E34453")
	static let logRadio = CBUUID(string: "0x5a3d6e49-06e6-4423-9944-e9de8cdf9547")
	static let logRadioLegacy = CBUUID(string: "0x6C6FD238-78FA-436B-AACF-15C5BE1EF2E2")
}
