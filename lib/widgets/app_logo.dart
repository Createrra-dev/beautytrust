import 'package:flutter/material.dart';

class AppAssets {
	AppAssets._();

	static const String logo = 'assets/images/app_logo.png';
	static const String onboarding1 = 'assets/images/onboarding_1.png';
	static const String onboarding2 = 'assets/images/onboarding_2.png';
	static const String onboarding3 = 'assets/images/onboarding_3.png';
}

class AppLogo extends StatelessWidget {
	const AppLogo({
		super.key,
		this.size = 72,
	});

	final double size;

	@override
	Widget build(BuildContext context) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(size * 0.22),
			child: Image.asset(
				AppAssets.logo,
				width: size,
				height: size,
				fit: BoxFit.cover,
			),
		);
	}
}
