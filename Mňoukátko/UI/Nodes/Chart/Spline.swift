/*
Mňoukátko - a Meshtastic® client

Copyright © 2012 The Android Open Source Project
Copyright © 2024 Radovan Paška

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
import Foundation

/**
 * Performs spline interpolation given a set of control points.
 */
public final class Spline {
	private var mX: [Float]
	private var mY: [Float]
	private var mM: [Float]

	private init(x: [Float], y: [Float], m: [Float]) {
		mX = x
		mY = y
		mM = m
	}

	/**
	 * Creates a -monotone- cubic spline from a given set of control points.
	 * <p/>
	 * The spline is guaranteed to pass through each control point exactly.
	 * Moreover, assuming the control points are monotonic (Y is non-decreasing or
	 * non-increasing) then the interpolated values will also be monotonic.
	 * <p/>
	 * This function uses the Fritsch-Carlson method for computing the spline parameters.
	 * http://en.wikipedia.org/wiki/Monotone_cubic_interpolation
	 *
	 * @param x The X component of the control points, strictly increasing.
	 * @param y The Y component of the control points, monotonic.
	 * @return
	 * @throws IllegalArgumentException if the X or Y arrays are null, have
	 *                                  different lengths or have fewer than 2 values.
	 * @throws IllegalArgumentException if the control points are not monotonic.
	 */
	public static func createMonotoneCubicSpline(x: [Float], y: [Float]) -> Spline? {
		guard x.count == y.count, x.count >= 2 else {
			return nil
		}

		let n = x.count

		var d: [Float] = []
		var m: [Float] = []

		// Compute slopes of secant lines between successive points.
		for i in 1...n - 1 {
			let h = x[i + 1] - x[i]
			if h <= 0 {
				return nil
			}

			d[i] = (y[i + 1] - y[i]) / h
		}

		// Initialize the tangents as the average of the secants.
		m[0] = d[0]
		for i in 1...n - 1 {
			m[i] = (d[i - 1] + d[i]) * 0.5
		}
		m[n - 1] = d[n - 2]

		// Update the tangents to preserve monotonicity.
		for i in 0...n - 1 {
			if d[i] == 0 { // successive Y values are equal
				m[i] = 0
				m[i + 1] = 0
			}
			else {
				let a = m[i] / d[i]
				let b = m[i + 1] / d[i]
				/*
				if (a < 0f || b < 0f) {
					throw new IllegalArgumentException(
						"The control points must have monotonic Y values."
					);
				}
				*/
				let h = Self.hypotenuse(a, b)
				if h > 9 {
					let t = Float(3) / h

					m[i] = t * a * d[i]
					m[i + 1] = t * b * d[i]
				}
			}
		}

		return Spline(x: x, y: y, m: m)
	}

	private static func hypotenuse<T: FloatingPoint>(_ a: T, _ b: T) -> T {
		(a * a + b * b).squareRoot()
	}

	/**
	 * Interpolates the value of Y = f(X) for given X.
	 * Clamps X to the domain of the spline.
	 *
	 * @param x The X value.
	 * @return The interpolated Y = f(X) value.
	 */
	public func interpolate(x: Float) -> Float {
		// Handle the boundary cases.
		let n = mX.count
		if x.isNaN {
			return x
		}
		if x <= mX[0] {
			return mY[0]
		}
		if x >= mX[n - 1] {
			return mY[n - 1]
		}

		// Find the index 'i' of the last point with smaller X.
		// We know this will be within the spline due to the boundary tests.
		var i = 0
		while x >= mX[i + 1] {
			i += 1

			if x == mX[i] {
				return mY[i]
			}
		}

		// Perform cubic Hermite spline interpolation.
		let h = mX[i + 1] - mX[i]
		let t = (x - mX[i]) / h

		return (mY[i] * (1 + 2 * t) + h * mM[i] * t) * (1 - t) * (1 - t)
			+ (mY[i + 1] * (3 - 2 * t) + h * mM[i + 1] * (t - 1)) * t * t
	}
}
