import 'package:flutter/material.dart';

class OnboardingPage {
	const OnboardingPage({
		this.title = '',
		this.description = '',
		this.icon,
		this.accentColor,
		this.imageAsset,
	});

	final String title;
	final String description;
	final IconData? icon;
	final Color? accentColor;
	final String? imageAsset;

	bool get hasImageLayout => imageAsset != null;
}
