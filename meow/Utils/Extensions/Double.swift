/*
Meow - the Meshtastic® client

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

extension Double {
	var toBytes: String {
	  let formatter = MeasurementFormatter()
	  let measurement = Measurement(value: self, unit: UnitInformationStorage.bytes)
	  formatter.unitStyle = .short
	  formatter.unitOptions = .naturalScale
	  formatter.numberFormatter.maximumFractionDigits = 0
	  return formatter.string(from: measurement.converted(to: .megabytes))
	}
}
