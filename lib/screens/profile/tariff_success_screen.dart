import 'package:flutter/material.dart';

import '../../models/tariff_payment_summary.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

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

		return Stack(
			children: [
				const _ConfettiBackground(),
				SafeArea(
					child: Padding(
						padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
						child: Column(
							children: [
								const Spacer(),
								const _SuccessBadge(),
								const SizedBox(height: 28),
								const Text(
									'Добро пожаловать',
									textAlign: TextAlign.center,
									style: TextStyle(
										color: AppColors.textPrimary,
										fontSize: 28,
										fontWeight: FontWeight.w700,
										height: 1.15,
									),
								),
								const SizedBox(height: 6),
								RichText(
									textAlign: TextAlign.center,
									text: const TextSpan(
										style: TextStyle(
											fontSize: 28,
											fontWeight: FontWeight.w700,
											height: 1.15,
										),
										children: [
											TextSpan(
												text: 'в ',
												style: TextStyle(color: AppColors.textPrimary),
											),
											TextSpan(
												text: 'Beauty',
												style: TextStyle(color: AppColors.primary),
											),
											TextSpan(
												text: 'Trust!',
												style: TextStyle(color: AppColors.textPrimary),
											),
										],
									),
								),
								const SizedBox(height: 10),
								const Text(
									'Ваша подписка активирована',
									textAlign: TextAlign.center,
									style: TextStyle(
										color: AppColors.textMuted,
										fontSize: 15,
									),
								),
								const SizedBox(height: 28),
								_SubscriptionInfoCard(
									planTitle: summary.plan.title,
									activeUntilLabel: activeUntilLabel,
								),
								const Spacer(),
								FilledButton(
									onPressed: () => _finish(context),
									style: FilledButton.styleFrom(
										padding: const EdgeInsets.symmetric(vertical: 16),
									),
									child: const Text('Начать работу'),
								),
								const SizedBox(height: 12),
								TextButton(
									onPressed: () => _finish(context),
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
				),
			],
		);
	}

	void _finish(BuildContext context) {
		Navigator.of(context).popUntil((route) => route.isFirst);
	}
}

class _SuccessBadge extends StatelessWidget {
	const _SuccessBadge();

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 96,
			height: 96,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				border: Border.all(
					color: AppColors.primary.withValues(alpha: 0.85),
					width: 4,
				),
				boxShadow: [
					BoxShadow(
						color: AppColors.secondary.withValues(alpha: 0.28),
						blurRadius: 28,
						spreadRadius: 2,
					),
				],
			),
			child: const Icon(
				Icons.check_rounded,
				color: AppColors.secondary,
				size: 52,
			),
		);
	}
}

class _SubscriptionInfoCard extends StatelessWidget {
	const _SubscriptionInfoCard({
		required this.planTitle,
		required this.activeUntilLabel,
	});

	final String planTitle;
	final String activeUntilLabel;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(
					color: AppColors.primary.withValues(alpha: 0.3),
				),
			),
			child: Row(
				children: [
					const AppLogo(size: 44),
					const SizedBox(width: 14),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Тариф $planTitle',
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
				],
			),
		);
	}
}

class _ConfettiBackground extends StatelessWidget {
	const _ConfettiBackground();

	static const _particles = [
		_ConfettiParticle(left: 0.12, top: 0.08, size: 7, rotation: 0.4, color: AppColors.secondary),
		_ConfettiParticle(left: 0.28, top: 0.14, size: 5, rotation: -0.6, color: AppColors.primary),
		_ConfettiParticle(left: 0.72, top: 0.1, size: 6, rotation: 0.9, color: AppColors.secondary),
		_ConfettiParticle(left: 0.86, top: 0.18, size: 5, rotation: -0.3, color: AppColors.primary),
		_ConfettiParticle(left: 0.18, top: 0.22, size: 4, rotation: 0.2, color: AppColors.primary),
		_ConfettiParticle(left: 0.58, top: 0.2, size: 6, rotation: -0.8, color: AppColors.secondary),
		_ConfettiParticle(left: 0.42, top: 0.12, size: 4, rotation: 0.5, color: AppColors.secondary),
		_ConfettiParticle(left: 0.9, top: 0.28, size: 4, rotation: 0.1, color: AppColors.primary),
	];

	@override
	Widget build(BuildContext context) {
		return LayoutBuilder(
			builder: (context, constraints) {
				return Stack(
					children: _particles.map((particle) {
						return Positioned(
							left: constraints.maxWidth * particle.left,
							top: constraints.maxHeight * particle.top,
							child: Transform.rotate(
								angle: particle.rotation,
								child: Container(
									width: particle.size,
									height: particle.size,
									decoration: BoxDecoration(
										color: particle.color.withValues(alpha: 0.85),
										borderRadius: BorderRadius.circular(1.5),
									),
								),
							),
						);
					}).toList(),
				);
			},
		);
	}
}

class _ConfettiParticle {
	const _ConfettiParticle({
		required this.left,
		required this.top,
		required this.size,
		required this.rotation,
		required this.color,
	});

	final double left;
	final double top;
	final double size;
	final double rotation;
	final Color color;
}
