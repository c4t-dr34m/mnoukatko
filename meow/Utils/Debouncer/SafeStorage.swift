/*
Meow - the Meshtastic® client

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

final class SafeStorage<T>: @unchecked Sendable {
	private let lock = NSRecursiveLock()
	private var stored: T

	init(stored: T) {
		self.stored = stored
	}

	func get() -> T {
		self.lock.lock()
		defer {
			self.lock.unlock()
		}

		return self.stored
	}

	func set(stored: T) {
		self.lock.lock()
		defer {
			self.lock.unlock()
		}

		self.stored = stored
	}

	func apply<R>(block: (inout T) -> R) -> R {
		self.lock.lock()
		defer {
			self.lock.unlock()
		}

		return block(&self.stored)
	}
}
