import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/client_check_result.dart';
import '../../models/client_profile.dart';
import '../../theme/app_theme.dart';

class ClientCheckResultPanel extends StatelessWidget {
	const ClientCheckResultPanel({
		super.key,
		required this.result,
		this.previewReviewsCount = 2,
	});

	final ClientCheckResult result;
	final int previewReviewsCount;

	@override
	Widget build(BuildContext context) {
		final profile = result.profile;
		final ratingColor = appointmentRatingColor(profile.reviewsAverage);
		final previewReviews = profile.reviews.take(previewReviewsCount).toList();

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_ClientHeader(
						clientName: result.clientName,
						profile: profile,
						ratingColor: ratingColor,
					),
					const SizedBox(height: 14),
					const Divider(color: AppColors.border, height: 1),
					const SizedBox(height: 14),
					_StatsRow(profile: profile, ratingColor: ratingColor),
					const SizedBox(height: 16),
					const Divider(color: AppColors.border, height: 1),
					const SizedBox(height: 16),
					_ReviewsPreview(reviews: previewReviews),
					const SizedBox(height: 16),
					_ReliabilityBanner(
						profile: profile,
						ratingColor: ratingColor,
					),
				],
			),
		);
	}
}

class _ClientHeader extends StatelessWidget {
	const _ClientHeader({
		required this.clientName,
		required this.profile,
		required this.ratingColor,
	});

	final String clientName;
	final ClientProfile profile;
	final Color ratingColor;

	@override
	Widget build(BuildContext context) {
		final initials = _initials(clientName);

		return Row(
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
				Container(
					decoration: BoxDecoration(
						shape: BoxShape.circle,
						border: Border.all(
							color: AppColors.border,
							width: 1.5,
						),
					),
					child: CircleAvatar(
						radius: 26,
						backgroundColor: AppColors.surfaceElevated,
						child: Text(
							initials,
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 17,
								fontWeight: FontWeight.w600,
							),
						),
					),
				),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						mainAxisSize: MainAxisSize.min,
						children: [
							Text(
								clientName,
								maxLines: 1,
								overflow: TextOverflow.ellipsis,
								style: const TextStyle(
									color: AppColors.textPrimary,
									fontSize: 16,
									fontWeight: FontWeight.w600,
								),
							),
							const SizedBox(height: 4),
							Text(
								profile.phone,
								style: const TextStyle(
									color: AppColors.textMuted,
									fontSize: 14,
								),
							),
						],
					),
				),
				const SizedBox(width: 8),
				_RatingWithBadge(
					rating: profile.reviewsAverage,
					label: profile.ratingLabel,
					ratingFontSize: 24,
					labelFontSize: 11,
				),
			],
		);
	}

	String _initials(String name) {
		final parts = name.trim().split(RegExp(r'\s+'));
		if (parts.length == 1) {
			return parts.first.substring(0, 1).toUpperCase();
		}

		return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
	}
}

class _StatsRow extends StatelessWidget {
	const _StatsRow({
		required this.profile,
		required this.ratingColor,
	});

	final ClientProfile profile;
	final Color ratingColor;

	@override
	Widget build(BuildContext context) {
		return IntrinsicHeight(
			child: Row(
				children: [
					Expanded(
						child: _StatTile(
							title: 'Отзывы мастеров',
							icon: Icons.star_rounded,
							iconColor: ratingColor,
							value: '${formatAppointmentRating(profile.reviewsAverage)}/5',
							subtitle: '${profile.reviewsCount} отзыва',
						),
					),
					const _VerticalDivider(),
					Expanded(
						child: _StatTile(
							title: 'Неявки',
							icon: Icons.event_busy_outlined,
							iconColor: AppColors.primary,
							value: '${profile.noShowsCount}',
							subtitle: 'за 6 мес.',
						),
					),
					const _VerticalDivider(),
					Expanded(
						child: _StatTile(
							title: 'Скандалы',
							icon: Icons.star_outline_rounded,
							iconColor: AppColors.primary,
							value: '${profile.scandalsCount}',
							subtitle: 'за 6 мес.',
						),
					),
				],
			),
		);
	}
}

class _VerticalDivider extends StatelessWidget {
	const _VerticalDivider();

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 1,
			margin: const EdgeInsets.symmetric(horizontal: 8),
			color: AppColors.border,
		);
	}
}

class _StatTile extends StatelessWidget {
	const _StatTile({
		required this.title,
		required this.icon,
		required this.iconColor,
		required this.value,
		required this.subtitle,
	});

	final String title;
	final IconData icon;
	final Color iconColor;
	final String value;
	final String subtitle;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					title,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 11,
						height: 1.2,
					),
				),
				const SizedBox(height: 8),
				Row(
					children: [
						Icon(icon, size: 16, color: iconColor),
						const SizedBox(width: 4),
						Flexible(
							child: Text(
								value,
								style: const TextStyle(
									color: AppColors.textPrimary,
									fontSize: 15,
									fontWeight: FontWeight.w700,
								),
							),
						),
					],
				),
				const SizedBox(height: 4),
				Text(
					subtitle,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 11,
					),
				),
			],
		);
	}
}

class _ReviewsPreview extends StatelessWidget {
	const _ReviewsPreview({required this.reviews});

	final List<MasterReview> reviews;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Row(
					children: [
						Expanded(
							child: Text(
								'Что говорят мастера',
								style: TextStyle(
									color: AppColors.textPrimary,
									fontSize: 16,
									fontWeight: FontWeight.w600,
								),
							),
						),
						Text(
							'Смотреть все',
							style: TextStyle(
								color: AppColors.primary,
								fontSize: 13,
								fontWeight: FontWeight.w600,
							),
						),
					],
				),
				const SizedBox(height: 12),
				...reviews.map(
					(review) => Padding(
						padding: const EdgeInsets.only(bottom: 12),
						child: _ReviewItem(review: review),
					),
				),
			],
		);
	}
}

class _ReviewItem extends StatelessWidget {
	const _ReviewItem({required this.review});

	final MasterReview review;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Row(
					children: [
						CircleAvatar(
							radius: 14,
							backgroundColor: AppColors.surfaceElevated,
							child: Text(
								review.masterName.substring(0, 1),
								style: const TextStyle(
									color: AppColors.textPrimary,
									fontSize: 11,
									fontWeight: FontWeight.w600,
								),
							),
						),
						const SizedBox(width: 8),
						Expanded(
							child: Text(
								review.masterName,
								style: const TextStyle(
									color: AppColors.textPrimary,
									fontSize: 14,
									fontWeight: FontWeight.w600,
								),
							),
						),
						_RatingWithBadge(
							rating: review.rating,
							label: review.tag,
							ratingFontSize: 15,
							labelFontSize: 10,
						),
					],
				),
				const SizedBox(height: 8),
				Text(
					review.text,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 13,
						height: 1.4,
					),
				),
			],
		);
	}
}

class _RatingWithBadge extends StatelessWidget {
	const _RatingWithBadge({
		required this.rating,
		required this.label,
		required this.ratingFontSize,
		required this.labelFontSize,
	});

	final double rating;
	final String label;
	final double ratingFontSize;
	final double labelFontSize;

	@override
	Widget build(BuildContext context) {
		final color = appointmentRatingColor(rating);

		return Column(
			crossAxisAlignment: CrossAxisAlignment.end,
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(
					formatAppointmentRating(rating),
					style: TextStyle(
						color: color,
						fontSize: ratingFontSize,
						fontWeight: FontWeight.w700,
						height: 1,
					),
				),
				const SizedBox(height: 4),
				_TextBadge(
					label: label,
					color: color,
					fontSize: labelFontSize,
				),
			],
		);
	}
}

class _TextBadge extends StatelessWidget {
	const _TextBadge({
		required this.label,
		required this.color,
		required this.fontSize,
	});

	final String label;
	final Color color;
	final double fontSize;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: color.withValues(alpha: 0.55)),
			),
			child: Text(
				label,
				style: TextStyle(
					color: color,
					fontSize: fontSize,
					fontWeight: FontWeight.w600,
					height: 1.2,
				),
			),
		);
	}
}

class _ReliabilityBanner extends StatelessWidget {
	const _ReliabilityBanner({
		required this.profile,
		required this.ratingColor,
	});

	final ClientProfile profile;
	final Color ratingColor;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: ratingColor.withValues(alpha: 0.08),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: ratingColor.withValues(alpha: 0.25)),
			),
			child: Row(
				children: [
					Icon(
						Icons.verified_user_outlined,
						color: ratingColor,
						size: 22,
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									profile.reliabilityTitle,
									style: TextStyle(
										color: ratingColor,
										fontSize: 14,
										fontWeight: FontWeight.w700,
									),
								),
								const SizedBox(height: 2),
								Text(
									profile.reliabilitySubtitle,
									style: const TextStyle(
										color: AppColors.textMuted,
										fontSize: 12,
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
