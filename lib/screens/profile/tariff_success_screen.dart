import 'package:flutter/material.dart';

import '../../models/tariff_payment_summary.dart';
import '../../theme/app_theme.dart';

class TariffSuccessScreen extends StatelessWidget {
	const TariffSuccessScreen({
		super.key,
		required this.summary,
	});

	static const routeName = '/tariff-success';

	final TariffPaymentSummary summary;

	@override
	Widget build(BuildContext context) {
		final activeUntil = DateTime.now().add(Duration(days: summary.months * 30));
		final activeUntilLabel =
			'${activeUntil.day.toString().padLeft(2, '0')}.'
			'${activeUntil.month.toString().padLeft(2, '0')}.'
			'${activeUntil.year}';

		return SafeArea(
			child: Padding(
				padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
				child: Column(
					children: [
						const Spacer(),
						Container(
							width: 88,
							height: 88,
							decoration: BoxDecoration(
								color: AppColors.secondary.withValues(alpha: 0.15),
								shape: BoxShape.circle,
								border: Border.all(
									color: AppColors.secondary.withValues(alpha: 0.35),
								),
							),
							child: const Icon(
								Icons.check_rounded,
								color: AppColors.secondary,
								size: 44,
							),
						),
						const SizedBox(height: 24),
						const Text(
							'Добро пожаловать в Beauty Trust!',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 24,
								fontWeight: FontWeight.w700,
								height: 1.2,
							),
						),
						const SizedBox(height: 8),
						const Text(
							'Ваша подписка активирована',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textMuted,
								fontSize: 15,
							),
						),
						const SizedBox(height: 24),
						Container(
							width: double.infinity,
							padding: const EdgeInsets.all(16),
							decoration: BoxDecoration(
								color: AppColors.surface,
								borderRadius: BorderRadius.circular(14),
								border: Border.all(
									color: AppColors.primary.withValues(alpha: 0.35),
								),
							),
							child: Column(
								children: [
									Text(
										'Тариф ${summary.plan.title}',
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 16,
											fontWeight: FontWeight.w600,
										),
									),
									const SizedBox(height: 4),
									Text(
										'Активен до $activeUntilLabel',
										style: const TextStyle(
											color: AppColors.textMuted,
											fontSize: 14,
										),
									),
								],
							),
						),
						const Spacer(),
						FilledButton(
							onPressed: () {
								Navigator.of(context).popUntil((route) => route.isFirst);
							},
							child: const Text('Начать работу'),
						),
						const SizedBox(height: 12),
						TextButton(
							onPressed: () {
								Navigator.of(context).popUntil((route) => route.isFirst);
							},
							child: const Text(
								'Перейти к профилю',
								style: TextStyle(
									color: AppColors.primary,
									fontSize: 14,
									fontWeight: FontWeight.w600,
								),
							),
						),
					],
				),
			),
		);
	}
}
