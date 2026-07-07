import 'package:flutter/material.dart';

class OnboardingFeature {
	const OnboardingFeature({
		required this.title,
		required this.description,
		required this.icon,
	});

	final String title;
	final String description;
	final IconData icon;
}

class OnboardingHighlight {
	const OnboardingHighlight({
		required this.title,
		required this.description,
		required this.icon,
	});

	final String title;
	final String description;
	final IconData icon;
}

class OnboardingTestimonial {
	const OnboardingTestimonial({
		required this.authorName,
		required this.role,
		required this.quote,
	});

	final String authorName;
	final String role;
	final String quote;
}

class OnboardingTextPart {
	const OnboardingTextPart({
		required this.text,
		this.color,
		this.useBrandGradient = false,
		this.fontSize = 30,
	});

	final String text;
	final Color? color;
	final bool useBrandGradient;
	final double fontSize;
}

class OnboardingPage {
	const OnboardingPage({
		required this.stepNumber,
		required this.titleParts,
		required this.subtitle,
		required this.features,
		this.highlight,
		this.testimonial,
		this.footerNote,
	});

	final int stepNumber;
	final List<OnboardingTextPart> titleParts;
	final String subtitle;
	final List<OnboardingFeature> features;
	final OnboardingHighlight? highlight;
	final OnboardingTestimonial? testimonial;
	final OnboardingFooterNote? footerNote;
}

class OnboardingFooterNote {
	const OnboardingFooterNote({
		required this.leading,
		required this.accent,
		required this.trailing,
		required this.caption,
		required this.icon,
	});

	final String leading;
	final String accent;
	final String trailing;
	final String caption;
	final IconData icon;
}
