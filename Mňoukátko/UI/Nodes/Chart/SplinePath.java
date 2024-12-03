/*
Mňoukátko - a Meshtastic® client

Copyright © 2014-2024 Radovan Paška

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
public abstract class SplinePath {
	private final ArrayList<XY> mPoints = new ArrayList<XY>();
	private final ArrayList<DeltaPoint> mPointsAligned = new ArrayList<DeltaPoint>();
	private final ArrayList<DeltaPoint> mPixels = new ArrayList<DeltaPoint>();
	private int[] mPadding;
	private Float mMaxY = null;
	private Spline mSpline;
	private Path mPath;
	private Paint mPaintPathStroke;
	private Paint mPaintPointBase;
	private Paint mPaintPointStroke;
	//
	private int mPathColor;
	private int mPathColor2;
	//
	protected boolean mFillPath = false;
	protected int mStrokeWidthRes = R.dimen.graph_stroke;
	protected int mPathColorRes = R.color.none;
	protected int mPathColor2Res = R.color.none;
	protected boolean mPathGradient = false;
	protected boolean mShowPoints = false;
	protected int mPointColorRes = R.color.none;
	protected int mPointSizeRes = R.dimen.graph_point;
	protected int mPointPaddingRes = R.dimen.graph_point_padding;
	//
	protected static final int GRADIENT_NONE = 0;
	protected static final int GRADIENT_HORIZONTAL = 1;
	protected static final int GRADIENT_VERTICAL = 1;

	public SplinePath() {
		// empty
	}

	public SplinePath(ArrayList<XY> XYs) {
		setData(XYs);
	}

	public void init(Resources resources) {
		// Load resources
		mPathColor = resources.getColor(mPathColorRes);
		mPathColor2 = resources.getColor(mPathColor2Res);

		final int pointColor = resources.getColor(mPointColorRes);
		final int strokeWidth = resources.getDimensionPixelSize(mStrokeWidthRes);
		final int pointSize;
		if (mPointSizeRes == 0) {
			pointSize = strokeWidth;
		} else {
			pointSize = resources.getDimensionPixelSize(mPointSizeRes);
		}
		final int pointPadding;
		if (mPointPaddingRes == 0) {
			pointPadding = 0;
		} else {
			pointPadding = resources.getDimensionPixelSize(mPointPaddingRes);
		}

		// Initialize paints
		mPaintPathStroke = new Paint(); // For the line itself
		mPaintPathStroke.setAntiAlias(true);
		mPaintPathStroke.setColor(mPathColor);
		mPaintPathStroke.setStrokeWidth(strokeWidth);
		mPaintPathStroke.setStrokeJoin(Paint.Join.ROUND);
		mPaintPathStroke.setStrokeCap(Paint.Cap.ROUND);
		if (mFillPath) {
			mPaintPathStroke.setStyle(Paint.Style.FILL);
		} else {
			mPaintPathStroke.setStyle(Paint.Style.STROKE);
		}

		mPaintPointBase = new Paint();
		mPaintPointBase.setAntiAlias(true);
		mPaintPointBase.setColor(Color.TRANSPARENT);
		mPaintPointBase.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
		mPaintPointBase.setStrokeWidth(pointSize + pointPadding);
		mPaintPointBase.setStyle(Paint.Style.FILL_AND_STROKE);

		mPaintPointStroke = new Paint();
		mPaintPointStroke.setAntiAlias(true);
		mPaintPointStroke.setColor(pointColor);
		mPaintPointStroke.setStrokeWidth(pointSize);
		mPaintPointStroke.setStyle(Paint.Style.FILL_AND_STROKE);

		// Initialize path
		mPath = new Path();
	}

	public void setData(List<XY> XYs) {
		synchronized (mPoints) {
			mPoints.clear();
			if (XYs != null) {
				mPoints.addAll(XYs);
			}
		}
	}

	public void setMaximumY(float max) {
		mMaxY = max;
	}

	public int getPixelValue(int x) {
		if (mPixels.size() <= x) {
			return 0;
		}

		if (x < 0) {
			x = 0;
		}

		return mPixels.get(x).y + mPadding[0];
	}

	public boolean isIncreasing(int x) {
		if (mPixels.size() <= (x + 1)) {
			return false;
		}

		if (x < 0) {
			x = 0;
		}

		int valueThis = mPixels.get(x).y;
		int valueNext = mPixels.get(x + 1).y;

		return (valueThis > valueNext); // It's drawn from top to bottom
	}

	public void alignToViewPort(int width, int height, int[] padding) {
		if (width == 0 || height == 0) {
			return;
		}
		mPadding = padding;

		// Set gradients
		if (mPathGradient) {
			final Shader shader = new LinearGradient(
				padding[3],
				0,
				width - padding[1],
				0,
				mPathColor,
				mPathColor2,
				Shader.TileMode.CLAMP
			);

			mPaintPathStroke.setShader(shader);
		}

		// Recalculate points
		if (mPoints.isEmpty()) {
			return;
		}

		final ArrayList<DeltaPoint> pixels = new ArrayList<DeltaPoint>();

		float xMin = Float.MAX_VALUE;
		float xMax = Float.MIN_VALUE;
		float yMin = Float.MAX_VALUE;
		float yMax = Float.MIN_VALUE;

		int graphW = width - padding[1] - padding[3];
		int graphH = height - padding[0] - padding[2];

		// Align points within viewport
		synchronized (mPoints) {
			for (XY point : mPoints) { // Find min/max
				xMin = Math.min(xMin, point.x);
				xMax = Math.max(xMax, point.x);
				yMin = Math.min(yMin, point.y);
				if (mMaxY == null) {
					yMax = Math.max(yMax, point.y);
				}
			}

			if (mMaxY != null) {
				yMax = mMaxY;
			}

			for (XY point : mPoints) { // Align pixels to available viewport
				float xPercent = (point.x - xMin) / (xMax - xMin);
				float yPercent = (point.y - yMin) / (yMax - yMin);

				int x = (int)(xPercent * graphW);
				int y = (int)(graphH - (graphH * yPercent));

				pixels.add(new DeltaPoint(x, y));
			}
		}

		// Store aligned points
		synchronized (mPointsAligned) {
			mPointsAligned.clear();
			mPointsAligned.addAll(pixels);
		}

		// Compute spline & interpolate each pixel on screen
		float[] x = new float[pixels.size()];
		float[] y = new float[pixels.size()];
		for (int i = 0; i < pixels.size(); i++) {
			DeltaPoint pixel = pixels.get(i);
			x[i] = pixel.x;
			y[i] = pixel.y;
		}

		mSpline = Spline.createMonotoneCubicSpline(x, y);

		ArrayList<DeltaPoint> curve = new ArrayList<DeltaPoint>(width);
		for (int i = 0; i < width; i++) {
			int curveY = (int)mSpline.interpolate(i);

			curve.add(i, new DeltaPoint(i, curveY));
		}

		synchronized (mPixels) {
			mPixels.clear();
			mPixels.addAll(curve);
		}

		// Clear path
		mPath.reset();

		// Create path, smooth point-to-point segments
		synchronized (mPixels) {
			if (mPixels.size() > 1) {
				for (int i = mPixels.size() - 2; i < mPixels.size(); i++) {
					if (i >= 0) {
						DeltaPoint point = mPixels.get(i);

						if (i == 0) {
							DeltaPoint next = mPixels.get(i + 1);
							point.dx = ((next.x - point.x) / 3);
							point.dy = ((next.y - point.y) / 3);
						} else if (i == mPixels.size() - 1) {
							DeltaPoint prev = mPixels.get(i - 1);
							point.dx = ((point.x - prev.x) / 3);
							point.dy = ((point.y - prev.y) / 3);
						} else {
							DeltaPoint next = mPixels.get(i + 1);
							DeltaPoint prev = mPixels.get(i - 1);
							point.dx = ((next.x - prev.x) / 3);
							point.dy = ((next.y - prev.y) / 3);
						}
					}
				}
			}

			boolean first = true;
			DeltaPoint point = null;

			// Always start at the bottom
			mPath.moveTo(
				padding[3],
				height + padding[0]
			);

			// Draw path
			for (int i = 0; i < mPixels.size(); i++) {
				point = mPixels.get(i);

				if (first) {
					mPath.lineTo(
						point.x + padding[3],
						point.y + padding[0]
					);

					first = false;
				} else {
					DeltaPoint prev = mPixels.get(i - 1);
					mPath.cubicTo(
						prev.x + prev.dx + padding[3],
						prev.y + prev.dy + padding[0],
						point.x - point.dx + padding[3],
						point.y - point.dy + padding[0],
						point.x + padding[3],
						point.y + padding[0]
					);
				}
			}

			// Always end at the bottom
			if (point != null) {
				mPath.lineTo(
					point.x + padding[3],
					height + padding[0]
				);
			}
		}
	}

	public void draw(Canvas canvas, int[] padding) {
		if (mSpline == null) {
			return;
		}

		// Draw curve
		canvas.drawPath(mPath, mPaintPathStroke);

		// Draw points
		if (mShowPoints) {
			synchronized (mPointsAligned) {
				for (DeltaPoint point : mPointsAligned) {
					if (point.y + padding[0] >= canvas.getHeight() - padding[2]) {
						continue;
					}

					canvas.drawCircle(
						point.x + padding[3],
						point.y + padding[0],
						mPaintPointBase.getStrokeWidth() / 2,
						mPaintPointBase
					);
					canvas.drawCircle(
						point.x + padding[3],
						point.y + padding[0],
						mPaintPointStroke.getStrokeWidth() / 2,
						mPaintPointStroke
					);
				}
			}
		}
	}
}
