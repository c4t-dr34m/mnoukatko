/*
Mňoukátko - a Meshtastic® client

Copyright © 2021 Garth Vander Houwen
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

	private let statusFontSize: CGFloat = 12
	private let statusIconSize: CGFloat = 10

	@Environment(\.managedObjectContext)
	private var context
	@Environment(\.colorScheme)
	private var colorScheme: ColorScheme
	@State
	private var isShowingDeleteConfirmation = false
	private var isDetectionSensorMessage: Bool {
		message.portNum == Int32(PortNum.detectionSensorApp.rawValue)
	}
	private var foregroundColor: Color {
		backgroundColor.isLight ? .black : .white
	}
	private var backgroundColor: Color {
		Color(
			UIColor.secondarySystemGroupedBackground
		)
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
									foregroundColor.opacity(0.8)
								)

							Text(payload)
								.font(.system(size: 14))
								.foregroundColor(foregroundColor)
								.opacity(0.8)
						}
						.padding(.vertical, 4)
						.padding(.horizontal, 8)
						.background(backgroundColor)
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(
									Color(.systemGroupedBackground),
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
							.foregroundColor(message.ackError > 0 ? foregroundColor.opacity(0.6) : foregroundColor)
							.tint(linkColor)
							.strikethrough(message.ackError > 0, color: .red)
							.padding(.top, 16)
							.padding(.bottom, 8)
							.padding(.leading, showSensor ? 0 : 16)
							.padding(.trailing, 16)

						Divider()
							.foregroundColor(.gray)

						HStack(alignment: .center, spacing: 4) {
							Spacer()

							if isCurrentUser {
								messageStatus
									.id(message.messageId)
							}
							else {
								messageTime
									.id(message.messageId)
							}

							recipient
							encryptionInfo
						}
						.padding(.bottom, 8)
						.padding(.trailing, 8)
					}
				}
				.background(backgroundColor)
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
	private var recipient: some View {
		if
			!isCurrentUser,
			!UserDefaults.preferredPeripheralIdList.isEmpty,
			let nodeUsed = message.toUser?.shortName
		{
			HStack(spacing: 4) {
				Divider()
					.frame(height: 12)
					.foregroundColor(.gray)

				Image(systemName: "tray.and.arrow.down")
					.font(.system(size: statusIconSize))
					.foregroundColor(foregroundColor.opacity(0.5))

				Text(nodeUsed)
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(foregroundColor.opacity(0.5))
					.fixedSize(horizontal: true, vertical: false)
			}
		}
	}

	@ViewBuilder
	private var messageTime: some View {
		HStack(spacing: 4) {
			Image(systemName: "clock")
				.font(.system(size: statusIconSize))
				.foregroundColor(foregroundColor.opacity(0.5))

			Text(message.timestamp.relative())
				.font(.system(size: statusFontSize))
				.lineLimit(1)
				.foregroundColor(foregroundColor.opacity(0.5))
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
					.foregroundColor(foregroundColor.opacity(0.5))

				Text(ackAt.relative())
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(foregroundColor.opacity(0.5))
			}
		}
		else if message.ackError == 0 {
			HStack(spacing: 4) {
				Image(systemName: "checkmark.circle.badge.questionmark")
					.font(.system(size: statusFontSize))
					.foregroundColor(.orange)

				Text(message.timestamp.relative())
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(foregroundColor.opacity(0.5))
			}
		}
		else if message.ackError > 0 {
			Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
				.font(.system(size: statusFontSize))
				.foregroundColor(.red)

			if let ackError = RoutingError(rawValue: Int(message.ackError)) {
				Text(ackError.display)
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(foregroundColor.opacity(0.5))
			}
			else {
				Text("Unknown ACK error")
					.font(.system(size: statusFontSize))
					.lineLimit(1)
					.foregroundColor(foregroundColor.opacity(0.5))
			}
		}
	}

	@ViewBuilder
	private var encryptionInfo: some View {
		if !isCurrentUser, message.toUser != nil {
			HStack(spacing: 4) {
				Divider()
					.frame(height: 12)
					.foregroundColor(.gray)

				if message.pkiEncrypted, let key = message.publicKey, !key.isEmpty {
					Image(systemName: "key")
						.font(.caption)
						.foregroundColor(.gray)
				}
				else {
					Image(systemName: "key.slash")
						.font(.caption)
						.foregroundColor(.gray)
				}
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
