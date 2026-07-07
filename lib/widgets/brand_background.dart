import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandBackground extends StatelessWidget {
	const BrandBackground({
		super.key,
		required this.child,
	});

	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Stack(
			children: [
				const Positioned.fill(
					child: DecoratedBox(
						decoration: BoxDecoration(
							color: AppColors.background,
							gradient: AppColors.glowGradient,
						),
					),
				),
				const Positioned.fill(
					child: DecoratedBox(
						decoration: BoxDecoration(
							gradient: AppColors.glowGradientSecondary,
						),
					),
				),
				child,
			],
		);
	}
}

class GradientText extends StatelessWidget {
	const GradientText(
		this.text, {
		super.key,
		this.style,
	});

	final String text;
	final TextStyle? style;

	@override
	Widget build(BuildContext context) {
		return ShaderMask(
			shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
			child: Text(
				text,
				style: (style ?? const TextStyle()).copyWith(color: Colors.white),
			),
		);
	}
}
