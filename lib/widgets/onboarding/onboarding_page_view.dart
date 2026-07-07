import 'package:flutter/material.dart';

import '../../models/onboarding_page.dart';
import '../../theme/app_theme.dart';
import '../app_logo.dart';
import '../brand_background.dart';
import '../brand_title.dart';

class OnboardingPageView extends StatelessWidget {
	const OnboardingPageView({
		super.key,
		required this.page,
		required this.pageIndex,
		required this.pageCount,
	});

	final OnboardingPage page;
	final int pageIndex;
	final int pageCount;

	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
			padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_OnboardingTopBar(
						pageIndex: pageIndex,
						pageCount: pageCount,
					),
					const SizedBox(height: 20),
					_OnboardingHero(
						stepNumber: page.stepNumber,
						titleParts: page.titleParts,
						subtitle: page.subtitle,
					),
					const SizedBox(height: 24),
					...page.features.map(
						(feature) => Padding(
							padding: const EdgeInsets.only(bottom: 14),
							child: OnboardingFeatureRow(feature: feature),
						),
					),
					if (page.highlight != null) ...[
						const SizedBox(height: 4),
						OnboardingHighlightCard(highlight: page.highlight!),
					],
					if (page.footerNote != null) ...[
						const SizedBox(height: 4),
						OnboardingFooterNoteCard(note: page.footerNote!),
					],
					if (page.testimonial != null) ...[
						const SizedBox(height: 4),
						OnboardingTestimonialCard(testimonial: page.testimonial!),
					],
				],
			),
		);
	}
}

class _OnboardingTopBar extends StatelessWidget {
	const _OnboardingTopBar({
		required this.pageIndex,
		required this.pageCount,
	});

	final int pageIndex;
	final int pageCount;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				const AppLogo(size: 34),
				const SizedBox(width: 10),
				const BrandTitle(fontSize: 17),
				const Spacer(),
				_OnboardingHeaderDots(
					pageIndex: pageIndex,
					pageCount: pageCount,
				),
			],
		);
	}
}

class _OnboardingHeaderDots extends StatelessWidget {
	const _OnboardingHeaderDots({
		required this.pageIndex,
		required this.pageCount,
	});

	final int pageIndex;
	final int pageCount;

	@override
	Widget build(BuildContext context) {
		return Row(
			mainAxisSize: MainAxisSize.min,
			children: List.generate(pageCount, (index) {
				final isActive = index == pageIndex;

				return Container(
					width: isActive ? 18 : 6,
					height: 6,
					margin: const EdgeInsets.only(left: 4),
					decoration: BoxDecoration(
						color: isActive
							? AppColors.primary
							: AppColors.surfaceElevated,
						borderRadius: BorderRadius.circular(6),
						border: isActive
							? null
							: Border.all(color: AppColors.border),
					),
				);
			}),
		);
	}
}

class _OnboardingHero extends StatelessWidget {
	const _OnboardingHero({
		required this.stepNumber,
		required this.titleParts,
		required this.subtitle,
	});

	final int stepNumber;
	final List<OnboardingTextPart> titleParts;
	final String subtitle;

	@override
	Widget build(BuildContext context) {
		return Stack(
			clipBehavior: Clip.none,
			children: [
				Positioned(
					top: -8,
					left: -4,
					child: Text(
						stepNumber.toString().padLeft(2, '0'),
						style: TextStyle(
							color: AppColors.primary.withValues(alpha: 0.14),
							fontSize: 72,
							fontWeight: FontWeight.w800,
							height: 1,
						),
					),
				),
				Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const SizedBox(height: 18),
						_OnboardingTitle(parts: titleParts),
						const SizedBox(height: 10),
						Text(
							subtitle,
							style: const TextStyle(
								color: AppColors.textMuted,
								fontSize: 15,
								height: 1.45,
							),
						),
					],
				),
			],
		);
	}
}

class _OnboardingTitle extends StatelessWidget {
	const _OnboardingTitle({required this.parts});

	final List<OnboardingTextPart> parts;

	@override
	Widget build(BuildContext context) {
		return RichText(
			text: TextSpan(
				style: const TextStyle(
					fontSize: 30,
					fontWeight: FontWeight.w700,
					height: 1.15,
					color: AppColors.textPrimary,
				),
				children: parts.map((part) {
					if (part.useBrandGradient) {
						return WidgetSpan(
							alignment: PlaceholderAlignment.baseline,
							baseline: TextBaseline.alphabetic,
							child: GradientText(
								part.text,
								style: TextStyle(
									fontSize: part.fontSize,
									fontWeight: FontWeight.w700,
									height: 1.15,
								),
							),
						);
					}

					return TextSpan(
						text: part.text,
						style: TextStyle(
							color: part.color ?? AppColors.textPrimary,
							fontSize: part.fontSize,
						),
					);
				}).toList(),
			),
		);
	}
}

class OnboardingFeatureRow extends StatelessWidget {
	const OnboardingFeatureRow({super.key, required this.feature});

	final OnboardingFeature feature;

	@override
	Widget build(BuildContext context) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Container(
					width: 44,
					height: 44,
					alignment: Alignment.center,
					decoration: BoxDecoration(
						color: AppColors.surface,
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: AppColors.primary.withValues(alpha: 0.35),
						),
					),
					child: Icon(
						feature.icon,
						color: AppColors.primary,
						size: 22,
					),
				),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								feature.title,
								style: const TextStyle(
									color: AppColors.primary,
									fontSize: 16,
									fontWeight: FontWeight.w600,
								),
							),
							const SizedBox(height: 4),
							Text(
								feature.description,
								style: const TextStyle(
									color: AppColors.textMuted,
									fontSize: 14,
									height: 1.4,
								),
							),
						],
					),
				),
			],
		);
	}
}

class OnboardingHighlightCard extends StatelessWidget {
	const OnboardingHighlightCard({super.key, required this.highlight});

	final OnboardingHighlight highlight;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				children: [
					Container(
						width: 40,
						height: 40,
						alignment: Alignment.center,
						decoration: BoxDecoration(
							color: AppColors.primary.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(10),
						),
						child: Icon(
							highlight.icon,
							color: AppColors.primary,
							size: 22,
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									highlight.title,
									style: const TextStyle(
										color: AppColors.primary,
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 4),
								Text(
									highlight.description,
									style: const TextStyle(
										color: AppColors.textMuted,
										fontSize: 13,
										height: 1.35,
									),
								),
							],
						),
					),
				],
			),
		);
	}
}

class OnboardingFooterNoteCard extends StatelessWidget {
	const OnboardingFooterNoteCard({super.key, required this.note});

	final OnboardingFooterNote note;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(
					color: AppColors.primary.withValues(alpha: 0.3),
				),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(
						note.icon,
						color: AppColors.primary,
						size: 22,
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								RichText(
									text: TextSpan(
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 14,
											height: 1.4,
										),
										children: [
											TextSpan(text: note.leading),
											TextSpan(
												text: note.accent,
												style: const TextStyle(
													color: AppColors.secondary,
													fontWeight: FontWeight.w600,
												),
											),
											TextSpan(text: note.trailing),
										],
									),
								),
								const SizedBox(height: 8),
								Text(
									note.caption,
									style: const TextStyle(
										color: AppColors.textMuted,
										fontSize: 12,
										height: 1.35,
									),
								),
							],
						),
					),
				],
			),
		);
	}
}

class OnboardingTestimonialCard extends StatelessWidget {
	const OnboardingTestimonialCard({super.key, required this.testimonial});

	final OnboardingTestimonial testimonial;

	@override
	Widget build(BuildContext context) {
		final initial = testimonial.authorName.isNotEmpty
			? testimonial.authorName[0].toUpperCase()
			: '?';

		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						width: 44,
						height: 44,
						alignment: Alignment.center,
						decoration: BoxDecoration(
							shape: BoxShape.circle,
							color: AppColors.surfaceElevated,
							border: Border.all(color: AppColors.border),
						),
						child: Text(
							initial,
							style: const TextStyle(
								color: AppColors.primary,
								fontSize: 18,
								fontWeight: FontWeight.w700,
							),
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									testimonial.authorName,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 2),
								Text(
									testimonial.role,
									style: const TextStyle(
										color: AppColors.primary,
										fontSize: 12,
									),
								),
								const SizedBox(height: 8),
								RichText(
									text: TextSpan(
										style: const TextStyle(
											color: AppColors.textMuted,
											fontSize: 13,
											height: 1.45,
										),
										children: [
											const TextSpan(
												text: '«',
												style: TextStyle(
													color: AppColors.primary,
													fontWeight: FontWeight.w700,
												),
											),
											TextSpan(text: testimonial.quote),
											const TextSpan(
												text: '»',
												style: TextStyle(
													color: AppColors.primary,
													fontWeight: FontWeight.w700,
												),
											),
										],
									),
								),
							],
						),
					),
				],
			),
		);
	}
}
