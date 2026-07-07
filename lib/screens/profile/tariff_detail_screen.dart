import 'package:flutter/material.dart';

import '../../models/tariff_plan.dart';
import '../../theme/app_theme.dart';
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
									_TariffDetailCard(
										plan: plan,
										onSelect: () {
											Navigator.of(context).pushNamed(
												TariffPaymentScreen.routeName,
												arguments: plan,
											);
										},
									),
									const SizedBox(height: 14),
									Container(
										padding: const EdgeInsets.symmetric(
											horizontal: 16,
											vertical: 12,
										),
										decoration: BoxDecoration(
											color: AppColors.surface,
											borderRadius: BorderRadius.circular(24),
											border: Border.all(color: AppColors.border),
										),
										child: const Text(
											'Экономия до 30% при годовой оплате',
											textAlign: TextAlign.center,
											style: TextStyle(
												color: AppColors.textMuted,
												fontSize: 13,
												height: 1.3,
											),
										),
									),
									const SizedBox(height: 28),
									const Row(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											Icon(
												Icons.shield_outlined,
												size: 16,
												color: AppColors.textMuted,
											),
											SizedBox(width: 6),
											Text(
												'Безопасная оплата',
												style: TextStyle(
													color: AppColors.textMuted,
													fontSize: 13,
													fontWeight: FontWeight.w500,
												),
											),
										],
									),
									const SizedBox(height: 14),
									const Row(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											_PaymentLogo(label: 'VISA'),
											SizedBox(width: 16),
											_PaymentLogo(label: 'Mastercard'),
											SizedBox(width: 16),
											_PaymentLogo(label: 'МИР'),
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

class _TariffDetailCard extends StatelessWidget {
	const _TariffDetailCard({
		required this.plan,
		required this.onSelect,
	});

	final TariffPlan plan;
	final VoidCallback onSelect;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(18),
				border: Border.all(
					color: AppColors.primary.withValues(alpha: 0.35),
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_TariffPriceLine(plan: plan),
					const SizedBox(height: 8),
					Text(
						plan.detailSubtitle,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 14,
							height: 1.4,
						),
					),
					const SizedBox(height: 22),
					...plan.features.map(
						(feature) => Padding(
							padding: const EdgeInsets.only(bottom: 12),
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Icon(
										Icons.check_rounded,
										size: 18,
										color: AppColors.textPrimary,
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
					),
					const SizedBox(height: 8),
					FilledButton(
						onPressed: onSelect,
						style: FilledButton.styleFrom(
							padding: const EdgeInsets.symmetric(vertical: 16),
						),
						child: const Text('Выбрать тариф'),
					),
				],
			),
		);
	}
}

class _TariffPriceLine extends StatelessWidget {
	const _TariffPriceLine({required this.plan});

	final TariffPlan plan;

	@override
	Widget build(BuildContext context) {
		if (plan.monthlyPrice == 0) {
			return Text(
				plan.priceLabel,
				style: const TextStyle(
					color: AppColors.primary,
					fontSize: 34,
					fontWeight: FontWeight.w700,
					height: 1.1,
				),
			);
		}

		return RichText(
			text: TextSpan(
				style: const TextStyle(
					fontSize: 34,
					fontWeight: FontWeight.w700,
					height: 1.1,
				),
				children: [
					TextSpan(
						text: '${plan.monthlyPrice}',
						style: const TextStyle(color: AppColors.primary),
					),
					const TextSpan(
						text: ' ₽ / мес.',
						style: TextStyle(color: AppColors.primary),
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

class _PaymentLogo extends StatelessWidget {
	const _PaymentLogo({required this.label});

	final String label;

	@override
	Widget build(BuildContext context) {
		return Text(
			label,
			style: const TextStyle(
				color: AppColors.textMuted,
				fontSize: 13,
				fontWeight: FontWeight.w700,
				letterSpacing: 0.4,
			),
		);
	}
}
