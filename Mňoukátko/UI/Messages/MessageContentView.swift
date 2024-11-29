/*
Mňoukátko - the Meshtastic® client

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
import MeshtasticProtobufs
import OSLog
import SwiftUI

struct MessageContentView: View {
	let message: MessageEntity
	let originalMessage: MessageEntity?
	let tapBackDestination: MessageDestination
	let isCurrentUser: Bool
	let onReply: () -> Void

	private let statusFontSize: CGFloat = 14
	private let statusIconSize: CGFloat = 12

	@Environment(\.managedObjectContext)
	private var context
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@State
	private var isShowingDeleteConfirmation = false
	private var isDetectionSensorMessage: Bool {
		message.portNum == Int32(PortNum.detectionSensorApp.rawValue)
	}
	private var linkColor: Color {
		if colorScheme == .dark {
			.white
		}
		else {
			.black
		}
	}

	private var corners: RectangleCornerRadii {
		if isCurrentUser {
			RectangleCornerRadii(
				topLeading: 16,
				bottomLeading: 16,
				bottomTrailing: 4,
				topTrailing: 16
			)
		}
		else {
			RectangleCornerRadii(
				topLeading: 4,
				bottomLeading: 16,
				bottomTrailing: 4,
				topTrailing: 16
			)
		}
	}

	var body: some View {
		ZStack(alignment: .topLeading) {
			let markdownText = message.messagePayloadMarkdown ?? (message.messagePayload ?? "Empty message received")

			VStack(alignment: isCurrentUser ? .trailing : .leading) {
				if
					let originalMessage,
					let payload = originalMessage.messagePayload
				{
					HStack(spacing: 0) {
						Spacer()
							.frame(width: 12)

						HStack {
							Image(systemName: "arrowshape.turn.up.left")
								.font(.system(size: 14))
								.symbolRenderingMode(.monochrome)
								.foregroundColor(
									getForegroundColor(
										for: originalMessage,
										isCurrentUser: isCurrentUser
									)
									.opacity(0.8)
								)

							Text(payload)
								.font(.system(size: 14))
								.foregroundColor(
									getForegroundColor(
										for: originalMessage,
										isCurrentUser: isCurrentUser
									)
								)
								.opacity(0.8)
						}
						.padding(.vertical, 4)
						.padding(.horizontal, 8)
						.background(getBackgroundColor(for: originalMessage, isCurrentUser: isCurrentUser))
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(
									colorScheme == .dark ? .black : .white,
									lineWidth: 3
								)
						)
						.clipShape(
							RoundedRectangle(cornerRadius: 8)
						)

						Spacer()
							.frame(width: 12)
					}
					.zIndex(1)
				}

				HStack(alignment: .center, spacing: 8) {
					let isDetectionSensorMessage = message.portNum == Int32(PortNum.detectionSensorApp.rawValue)
					let showSensor = tapBackDestination.overlaySensorMessage && isDetectionSensorMessage

					if showSensor {
						Image(systemName: "sensor.fill")
							.font(.body)
							.foregroundColor(.gray)
							.symbolEffect(
								.variableColor.reversing.cumulative,
								options: .repeat(.max).speed(2)
							)
							.padding(.top, 18)
							.padding(.bottom, 18)
							.padding(.leading, 16)

						Divider()
					}

					VStack(alignment: .leading, spacing: 8) {
						Text(markdownText)
							.font(.body)
							.foregroundColor(
								getForegroundColor(
									for: message,
									isCurrentUser: isCurrentUser
								)
							)
							.tint(linkColor)
							.strikethrough(message.ackError > 0)
							.padding(.top, 16)
							.padding(.bottom, 8)
							.padding(.leading, showSensor ? 0 : 16)
							.padding(.trailing, 16)

						Divider()
							.foregroundColor(.gray)

						HStack(alignment: .center) {
							Spacer()

							if isCurrentUser {
								messageStatus
									.padding(.leading, 4)
									.padding(.bottom, 4)
									.id(message.messageId)
							}
							else {
								messageTime
									.padding(.leading, 4)
									.padding(.bottom, 4)
									.id(message.messageId)
							}

							Divider()
								.frame(height: 10)
								.foregroundColor(.gray)

							if message.pkiEncrypted {
								Image(systemName: "key")
									.font(.caption)
									.foregroundColor(.gray)
									.padding(.trailing, 8)
									.padding(.bottom, 4)
							}
							else {
								Image(systemName: "key.slash")
									.font(.caption)
									.foregroundColor(.gray)
									.padding(.trailing, 8)
									.padding(.bottom, 4)
							}
						}
					}
				}
				.background(getBackgroundColor(for: message, isCurrentUser: isCurrentUser))
				.clipShape(
					UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
				)
				.padding(.top, originalMessage == nil ? 0 : -22)
				.contextMenu {
					MessageContextMenuItems(
						isShowingDeleteConfirmation: $isShowingDeleteConfirmation,
						message: message,
						tapBackDestination: tapBackDestination,
						isCurrentUser: isCurrentUser,
						onReply: onReply
					)
				}
				.confirmationDialog(
					"Are you sure you want to delete this message?",
					isPresented: $isShowingDeleteConfirmation,
					titleVisibility: .visible
				) {
					Button("Delete Message", role: .destructive) {
						context.delete(message)
						try? context.save()
					}

					Button("Cancel", role: .cancel) { }
				}
			}
		}
	}

	@ViewBuilder
	private var messageTime: some View {
		HStack(spacing: 4) {
			Image(systemName: "clock")
				.font(.system(size: statusIconSize))
				.foregroundColor(getForegroundColor(for: message).opacity(0.5))

			Text(message.timestamp.relative())
				.font(.system(size: statusFontSize))
				.lineLimit(1)
				.foregroundColor(getForegroundColor(for: message).opacity(0.5))
				.fixedSize(horizontal: true, vertical: false)
		}
	}

	@ViewBuilder
	private var messageStatus: some View {
		if message.receivedACK {
			let ackAt = Date(timeIntervalSince1970: TimeInterval(message.ackTimestamp))

			HStack(spacing: 4) {
				Image(systemName: "checkmark.circle.fill")
					.font(.system(size: statusFontSize))
					.foregroundColor(getForegroundColor(for: message).opacity(0.5))

				Text(ackAt.relative())
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(getForegroundColor(for: message).opacity(0.5))
			}
		}
		else if message.ackError == 0 {
			HStack(spacing: 4) {
				Image(systemName: "checkmark.circle.badge.questionmark")
					.font(.system(size: statusFontSize))
					.foregroundColor(getForegroundColor(for: message).opacity(0.5))

				Text(message.timestamp.relative())
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(getForegroundColor(for: message).opacity(0.5))
			}
		}
		else if message.ackError > 0 {
			Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
				.font(.system(size: statusFontSize))
				.foregroundColor(getForegroundColor(for: message).opacity(0.5))

			if let ackError = RoutingError(rawValue: Int(message.ackError)) {
				Text(ackError.display)
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(getForegroundColor(for: message).opacity(0.5))
			}
			else {
				Text("Unknown ACK error")
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(getForegroundColor(for: message).opacity(0.5))
			}
		}
	}

	private func getBackgroundColor(
		for message: MessageEntity,
		isCurrentUser: Bool
	) -> Color {
		if UserDefaults.moreColors {
			if let num = message.fromUser?.num {
				return Color(
					UIColor(hex: UInt32(num))
				)
			}
			else {
				if isCurrentUser {
					return Color.accentColor
				}
				else {
					if colorScheme == .dark {
						return Color(white: 0.1)
					}
					else {
						return Color(white: 0.9)
					}
				}
			}
		}
		else {
			if colorScheme == .dark {
				return Color(white: 0.1)
			}
			else {
				return Color(white: 0.9)
			}
		}
	}

	private func getForegroundColor(
		for message: MessageEntity,
		isCurrentUser: Bool = false
	) -> Color {
		let background = getBackgroundColor(for: message, isCurrentUser: isCurrentUser)

		if UserDefaults.moreColors {
			if background.isLight() {
				return Color.black
			}
			else {
				return Color.white
			}
		}
		else {
			if background.isLight() {
				return Color.black
			}
			else {
				return Color.white
			}
		}
	}
}

private extension MessageDestination {
	var overlaySensorMessage: Bool {
		switch self {
		case .user:
			return false

		case .channel:
			return true
		}
	}
}
