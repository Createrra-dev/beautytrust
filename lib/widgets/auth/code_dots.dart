import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CodeDots extends StatelessWidget {
	const CodeDots({
		super.key,
		required this.length,
		required this.filledCount,
		this.dotSize = 16,
	});

	final int length;
	final int filledCount;
	final double dotSize;

	@override
	Widget build(BuildContext context) {
		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: List.generate(length, (index) {
				final isFilled = index < filledCount;
				return Container(
					width: dotSize,
					height: dotSize,
					margin: const EdgeInsets.symmetric(horizontal: 12),
					decoration: BoxDecoration(
						shape: BoxShape.circle,
						color: isFilled
							? AppColors.primary
							: AppColors.surfaceElevated.withValues(alpha: 0.5),
						border: isFilled
							? null
							: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
					),
				);
			}),
		);
	}
}
