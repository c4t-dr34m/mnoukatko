/*
Meow - the Meshtastic® client

Copyright (C) 2024 Radovan Paška

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

struct StateMachine<T> {
	enum State {
		case idle
		case debouncing(value: T, dueTime: ContinuousClock.Instant, isValueDuringSleep: Bool)
	}

	enum SleepIsOverAction {
		case continueDebouncing(dueTime: ContinuousClock.Instant)
		case finishDebouncing(value: T)
	}

	let duration: ContinuousClock.Duration

	var state: State

	init(duration: ContinuousClock.Duration) {
		self.state = .idle
		self.duration = duration
	}

	mutating func newValue(_ value: T) -> (Bool, ContinuousClock.Instant) {
		let dueTime = ContinuousClock.now + duration

		switch self.state {
		case .idle:
			// there is no value being debounced
			self.state = .debouncing(value: value, dueTime: dueTime, isValueDuringSleep: false)
			// we should start a new task to begin the debounce
			return (true, dueTime)

		case .debouncing:
			// there is already a value being debounced
			// the new value takes its place and we update the due time
			self.state = .debouncing(value: value, dueTime: dueTime, isValueDuringSleep: true)
			// no need to create a new task, we extend the lifespan of the current task
			return (false, dueTime)
		}
	}

	mutating func sleepIsOver() -> SleepIsOverAction {
		switch self.state {
		case .idle:
			fatalError("inconsistent state, no value was being debounced.")

		case .debouncing(let value, let dueTime, true):
			// one or more values have been set while sleeping
			state = .debouncing(value: value, dueTime: dueTime, isValueDuringSleep: false)
			// we have to continue debouncing with the latest value
			return .continueDebouncing(dueTime: dueTime)

		case .debouncing(let value, _, false):
			// no values were set while sleeping
			state = .idle
			// we can output the latest known value
			return .finishDebouncing(value: value)
		}
	}
}
