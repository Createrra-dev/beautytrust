import 'package:flutter/material.dart';

class AppAssets {
	AppAssets._();

	static const String logo = 'assets/images/app_logo.png';
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
