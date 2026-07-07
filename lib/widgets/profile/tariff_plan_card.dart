import 'package:flutter/material.dart';

import '../../models/tariff_plan.dart';
import '../../theme/app_theme.dart';

class TariffPlanCard extends StatelessWidget {
	const TariffPlanCard({
		super.key,
		required this.plan,
		required this.onButtonPressed,
	});

	final TariffPlan plan;
	final VoidCallback onButtonPressed;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(18),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(
					color: plan.isPopular
						? AppColors.primary.withValues(alpha: 0.45)
						: AppColors.border,
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Expanded(
								child: Text(
									plan.title,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 20,
										fontWeight: FontWeight.w700,
									),
								),
							),
							if (plan.isPopular)
								Container(
									padding: const EdgeInsets.symmetric(
										horizontal: 8,
										vertical: 3,
									),
									decoration: BoxDecoration(
										color: AppColors.primary.withValues(alpha: 0.15),
										borderRadius: BorderRadius.circular(8),
									),
									child: const Text(
										'Популярный',
										style: TextStyle(
											color: AppColors.primary,
											fontSize: 11,
											fontWeight: FontWeight.w600,
										),
									),
								),
						],
					),
					const SizedBox(height: 8),
					Text(
						plan.priceLabel,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 28,
							fontWeight: FontWeight.w700,
							height: 1.1,
						),
					),
					const SizedBox(height: 4),
					Text(
						plan.trialLabel,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
						),
					),
					const SizedBox(height: 16),
					...plan.features.map(
						(feature) => Padding(
							padding: const EdgeInsets.only(bottom: 10),
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Icon(
										Icons.check_circle_rounded,
										size: 18,
										color: AppColors.primary,
									),
									const SizedBox(width: 10),
									Expanded(
										child: Text(
											feature,
											style: const TextStyle(
												color: AppColors.textPrimary,
												fontSize: 14,
												height: 1.35,
											),
										),
									),
								],
							),
						),
					),
					const SizedBox(height: 8),
					FilledButton(
						onPressed: onButtonPressed,
						child: Text(plan.cardButtonLabel),
					),
				],
			),
		);
	}
}

class TariffFeatureList extends StatelessWidget {
	const TariffFeatureList({super.key, required this.features});

	final List<String> features;

	@override
	Widget build(BuildContext context) {
		return Column(
			children: features.map(
				(feature) => Padding(
					padding: const EdgeInsets.only(bottom: 12),
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Icon(
								Icons.check_circle_rounded,
								size: 20,
								color: AppColors.primary,
							),
							const SizedBox(width: 12),
							Expanded(
								child: Text(
									feature,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 15,
										height: 1.35,
									),
								),
							),
						],
					),
				),
			).toList(),
		);
	}
}
