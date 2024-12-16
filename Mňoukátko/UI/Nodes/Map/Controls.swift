/*
Mňoukátko - a Meshtastic® client

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
import MapKit
import SwiftUI

struct Controls: View {
	private let defaultDistance: Double = 200
	private let iconSize: CGFloat = 20
	private let iconPadding: CGFloat = 8

	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@Binding
	private var position: MapCameraPosition
	@Binding
	private var distance: Double?
	@Binding
	private var heading: Double?
	@Binding
	private var nodeHistory: Bool?
	private var buttonBackground: Color {
		if colorScheme == .dark {
			return .black.opacity(0.65)
		}
		else {
			return .white.opacity(0.85)
		}
	}
	private var headingFormatted: String {
		guard let heading else {
			return "N"
		}

		if 22.5...67.5 ~= heading {
			return "NE"
		}
		else if 67.5...112.5 ~= heading {
			return "E"
		}
		else if 112.5...157.5 ~= heading {
			return "SE"
		}
		else if 157.5...202.5 ~= heading {
			return "S"
		}
		else if 202.5...247.5 ~= heading {
			return "SW"
		}
		else if 247.5...292.5 ~= heading {
			return "W"
		}
		else if 292.5...337.5 ~= heading {
			return "NW"
		}
		else {
			return "N"
		}
	}

	var body: some View {
		VStack(alignment: .center, spacing: 4) {
			Button {
				if let location = LocationManager.shared.getLocation() {
					position = .camera(
						MapCamera(
							centerCoordinate: location.coordinate,
							distance: distance ?? defaultDistance,
							heading: 0
						)
					)
				}
				else if let center = position.camera?.centerCoordinate {
					position = .camera(
						MapCamera(
							centerCoordinate: center,
							distance: distance ?? defaultDistance,
							heading: 0
						)
					)
				}
			} label: {
				VStack(alignment: .center, spacing: 4) {
					Image(systemName: "location.fill")
						.rotationEffect(
							Angle(degrees: (360 - (heading ?? 0)) - 45) // the icon itself is rotated by 45°cw
						)
						.font(.system(size: iconSize))
						.symbolRenderingMode(.hierarchical)
						.foregroundColor(.red)
						.frame(width: iconSize, height: iconSize)

					Text(headingFormatted)
						.font(.system(size: 12, weight: .light))
						.foregroundStyle(.gray)
						.lineLimit(1)
				}
				.padding(.all, iconPadding)
				.background(buttonBackground)
				.overlay(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.stroke(.tertiary, lineWidth: 1)
				)
				.clipShape(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
				)
				.padding(.top, 8)
				.padding(.horizontal, 8)
			}

			if nodeHistory != nil {
				Spacer()

				Button {
					if nodeHistory == true {
						nodeHistory = false
						UserDefaults.mapNodeHistory = false
					}
					else {
						nodeHistory = true
						UserDefaults.mapNodeHistory = true
					}
				} label: {
					Image(systemName: nodeHistory == true ? "clock.fill" : "clock")
						.font(.system(size: iconSize))
						.symbolRenderingMode(.hierarchical)
						.foregroundColor(.accentColor)
						.frame(width: iconSize, height: iconSize)
						.padding(.all, iconPadding)
						.background(buttonBackground)
						.overlay(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.stroke(.tertiary, lineWidth: 1)
						)
						.clipShape(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
						)
						.padding(.bottom, 8)
						.padding(.horizontal, 8)
				}
			}
		}
	}

	init(
		position: Binding<MapCameraPosition>,
		distance: Binding<Double?>,
		heading: Binding<Double?>,
		nodeHistory: Binding<Bool?> = .constant(nil)
	) {
		self._position = position
		self._distance = distance
		self._heading = heading
		self._nodeHistory = nodeHistory
	}
}
