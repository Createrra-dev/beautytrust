import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SparklineChart extends StatelessWidget {
	const SparklineChart({
		super.key,
		required this.values,
		this.height = 72,
	});

	final List<double> values;
	final double height;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			height: height,
			child: CustomPaint(
				painter: _SparklinePainter(values: values),
				child: const SizedBox.expand(),
			),
		);
	}
}

class _SparklinePainter extends CustomPainter {
	_SparklinePainter({required this.values});

	final List<double> values;

	@override
	void paint(Canvas canvas, Size size) {
		if (values.length < 2) {
			return;
		}

		final points = <Offset>[];
		for (var index = 0; index < values.length; index++) {
			final x = size.width * index / (values.length - 1);
			final y = size.height - (values[index].clamp(0.0, 1.0) * size.height);
			points.add(Offset(x, y));
		}

		final linePath = Path()..moveTo(points.first.dx, points.first.dy);
		for (var index = 1; index < points.length; index++) {
			linePath.lineTo(points[index].dx, points[index].dy);
		}

		final fillPath = Path.from(linePath)
			..lineTo(size.width, size.height)
			..lineTo(0, size.height)
			..close();

		final fillPaint = Paint()
			..shader = LinearGradient(
				begin: Alignment.topCenter,
				end: Alignment.bottomCenter,
				colors: [
					AppColors.secondary.withValues(alpha: 0.35),
					AppColors.secondary.withValues(alpha: 0.0),
				],
			).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

		canvas.drawPath(fillPath, fillPaint);

		final glowPaint = Paint()
			..color = AppColors.secondary.withValues(alpha: 0.45)
			..strokeWidth = 4
			..style = PaintingStyle.stroke
			..strokeCap = StrokeCap.round
			..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

		canvas.drawPath(linePath, glowPaint);

		final linePaint = Paint()
			..color = AppColors.secondary
			..strokeWidth = 2
			..style = PaintingStyle.stroke
			..strokeCap = StrokeCap.round
			..strokeJoin = StrokeJoin.round;

		canvas.drawPath(linePath, linePaint);
	}

	@override
	bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
		return oldDelegate.values != values;
	}
}
