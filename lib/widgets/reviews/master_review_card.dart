import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/client_profile.dart';
import '../../theme/app_theme.dart';

class MasterReviewCard extends StatelessWidget {
	const MasterReviewCard({
		super.key,
		required this.review,
	});

	final MasterReview review;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: AppColors.surfaceElevated,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							CircleAvatar(
								radius: 14,
								backgroundColor: AppColors.surface,
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
							_ReviewRatingMeta(review: review),
						],
					),
					const SizedBox(height: 10),
					Text(
						review.text,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
							height: 1.4,
						),
					),
				],
			),
		);
	}
}

class _ReviewRatingMeta extends StatelessWidget {
	const _ReviewRatingMeta({required this.review});

	final MasterReview review;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.end,
			mainAxisSize: MainAxisSize.min,
			children: [
				ReviewRatingBadge(
					rating: review.rating,
					label: review.tag,
					ratingFontSize: 15,
					labelFontSize: 10,
				),
				if (review.ratedAt != null) ...[
					const SizedBox(height: 4),
					Text(
						formatReviewMonthYear(review.ratedAt!),
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 10,
							height: 1.2,
						),
					),
				],
			],
		);
	}
}

class ReviewRatingBadge extends StatelessWidget {
	const ReviewRatingBadge({
		super.key,
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
