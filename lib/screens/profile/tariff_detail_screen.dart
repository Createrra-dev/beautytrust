import 'package:flutter/material.dart';

import '../../models/tariff_plan.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile/tariff_plan_card.dart';
import 'tariff_payment_screen.dart';

class TariffDetailScreen extends StatelessWidget {
	const TariffDetailScreen({
		super.key,
		required this.plan,
	});

	static const routeName = '/tariff-detail';

	final TariffPlan plan;

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Тариф ${plan.title}',
						onBack: () => Navigator.of(context).pop(),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Text(
										plan.priceLabel,
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 34,
											fontWeight: FontWeight.w700,
											height: 1.1,
										),
									),
									const SizedBox(height: 8),
									Text(
										plan.detailSubtitle,
										style: const TextStyle(
											color: AppColors.textMuted,
											fontSize: 14,
											height: 1.4,
										),
									),
									const SizedBox(height: 24),
									TariffFeatureList(features: plan.features),
									const SizedBox(height: 24),
									FilledButton(
										onPressed: () {
											Navigator.of(context).pushNamed(
												TariffPaymentScreen.routeName,
												arguments: plan,
											);
										},
										child: const Text('Выбрать тариф'),
									),
									const SizedBox(height: 16),
									const Text(
										'Экономия до 30% при годовой оплате',
										textAlign: TextAlign.center,
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 13,
										),
									),
									const SizedBox(height: 12),
									const Text(
										'Безопасная оплата',
										textAlign: TextAlign.center,
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 13,
											fontWeight: FontWeight.w500,
										),
									),
									const SizedBox(height: 8),
									const Row(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											_PaymentBadge(label: 'VISA'),
											SizedBox(width: 8),
											_PaymentBadge(label: 'MC'),
											SizedBox(width: 8),
											_PaymentBadge(label: 'МИР'),
										],
									),
								],
							),
						),
					),
				],
			),
		);
	}
}

class _PageHeader extends StatelessWidget {
	const _PageHeader({
		required this.title,
		required this.onBack,
	});

	final String title;
	final VoidCallback onBack;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
			child: Row(
				children: [
					IconButton(
						onPressed: onBack,
						icon: const Icon(
							Icons.arrow_back_ios_new_rounded,
							color: AppColors.textPrimary,
							size: 20,
						),
					),
					Expanded(
						child: Text(
							title,
							textAlign: TextAlign.center,
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 18,
								fontWeight: FontWeight.w600,
							),
						),
					),
					const SizedBox(width: 48),
				],
			),
		);
	}
}

class _PaymentBadge extends StatelessWidget {
	const _PaymentBadge({required this.label});

	final String label;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(8),
				border: Border.all(color: AppColors.border),
			),
			child: Text(
				label,
				style: const TextStyle(
					color: AppColors.textMuted,
					fontSize: 11,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}
