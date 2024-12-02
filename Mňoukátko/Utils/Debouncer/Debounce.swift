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
public final class Debounce<T>: Sendable {
	private let output: @Sendable (T) async -> Void
	private let stateMachine: SafeStorage<StateMachine<T>>
	private let task: SafeStorage<Task<Void, Never>?>

	public init(
		duration: ContinuousClock.Duration,
		output: @Sendable @escaping (T) async -> Void
	) {
		self.stateMachine = SafeStorage(stored: StateMachine(duration: duration))
		self.task = SafeStorage(stored: nil)
		self.output = output
	}

	public func emit(value: T) {
		let (shouldStartATask, dueTime) = self.stateMachine.apply { machine in
			machine.newValue(value)
		}

		if shouldStartATask {
			self.task.set(stored: Task { [output, stateMachine] in
				var localDueTime = dueTime

				loop: while true {
					try? await Task.sleep(until: localDueTime, clock: .continuous)

					let action = stateMachine.apply { machine in
						machine.sleepIsOver()
					}

					switch action {
					case .finishDebouncing(let value):
						await output(value)
						break loop

					case .continueDebouncing(let newDueTime):
						localDueTime = newDueTime
						continue loop
					}
				}
			})
		}
	}

	deinit {
		task.get()?.cancel()
	}
}
