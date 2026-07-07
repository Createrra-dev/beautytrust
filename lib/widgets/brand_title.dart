import 'package:flutter/material.dart';

import '../config/app_branding.dart';
import '../theme/app_theme.dart';

class BrandTitle extends StatelessWidget {
	const BrandTitle({
		super.key,
		this.fontSize = 18,
	});

	final double fontSize;

	@override
	Widget build(BuildContext context) {
		return RichText(
			text: TextSpan(
				style: TextStyle(
					fontSize: fontSize,
					fontWeight: FontWeight.w700,
				),
				children: const [
					TextSpan(
						text: 'Beauty',
						style: TextStyle(color: AppColors.primary),
					),
					TextSpan(
						text: ' Trust',
						style: TextStyle(color: AppColors.textPrimary),
					),
				],
			),
		);
	}
}

class BrandSlogan extends StatelessWidget {
	const BrandSlogan({
		super.key,
		this.fontSize = 14,
		this.textAlign = TextAlign.center,
	});

	final double fontSize;
	final TextAlign textAlign;

	@override
	Widget build(BuildContext context) {
		return Text(
			AppBranding.slogan,
			textAlign: textAlign,
			style: TextStyle(
				fontSize: fontSize,
				height: 1.4,
				color: AppColors.textMuted,
			),
		);
	}
}
