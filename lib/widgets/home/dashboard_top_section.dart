import 'package:flutter/material.dart';

import '../../models/dashboard_stats.dart';
import '../../theme/app_theme.dart';
import '../app_logo.dart';
import '../brand_title.dart';
import 'sparkline_chart.dart';

class DashboardTopSection extends StatelessWidget {
	const DashboardTopSection({
		super.key,
		required this.stats,
		this.onPeriodTap,
	});

	final DashboardStats stats;
	final VoidCallback? onPeriodTap;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Row(
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						const AppLogo(size: 36),
						const SizedBox(width: 10),
						const Expanded(
							child: BrandTitle(fontSize: 18),
						),
						PeriodSelector(
							periodLabel: stats.periodLabel,
							onTap: onPeriodTap,
							alignEnd: true,
						),
					],
				),
				const SizedBox(height: 20),
				ProtectedIncomeCard(stats: stats),
				const SizedBox(height: 12),
				Row(
					children: [
						Expanded(
							child: DashboardStatCard(
								title: 'Неявки предотвращены',
								value: '${stats.preventedNoShows}',
								trendLabel: stats.noShowsTrendLabel,
								trendPositive: false,
							),
						),
						const SizedBox(width: 12),
						Expanded(
							child: DashboardStatCard(
								title: 'Проверок выполнено',
								value: '${stats.completedChecks}',
								trendLabel: stats.checksTrendLabel,
								trendPositive: true,
							),
						),
					],
				),
			],
		);
	}
}

class PeriodSelector extends StatelessWidget {
	const PeriodSelector({
		super.key,
		required this.periodLabel,
		this.onTap,
		this.alignEnd = false,
	});

	final String periodLabel;
	final VoidCallback? onTap;
	final bool alignEnd;

	@override
	Widget build(BuildContext context) {
		final labelAlignment = alignEnd
			? CrossAxisAlignment.end
			: CrossAxisAlignment.start;

		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(12),
				child: Padding(
					padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							Column(
								crossAxisAlignment: labelAlignment,
								children: [
									const Text(
										'Период',
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 13,
										),
									),
									const SizedBox(height: 2),
									Text(
										periodLabel,
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 18,
											fontWeight: FontWeight.w600,
										),
									),
								],
							),
							const SizedBox(width: 8),
							const Icon(
								Icons.keyboard_arrow_down_rounded,
								color: AppColors.textMuted,
								size: 22,
							),
						],
					),
				),
			),
		);
	}
}

class ProtectedIncomeCard extends StatelessWidget {
	const ProtectedIncomeCard({
		super.key,
		required this.stats,
	});

	final DashboardStats stats;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Защищено дохода',
									style: TextStyle(
										color: AppColors.textMuted,
										fontSize: 14,
									),
								),
								const SizedBox(height: 8),
								Text(
									formatRubles(stats.protectedIncome),
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 32,
										fontWeight: FontWeight.w700,
										height: 1.1,
									),
								),
								const SizedBox(height: 8),
								Text(
									stats.incomeTrendLabel,
									style: TextStyle(
										color: stats.incomeTrendPositive
											? AppColors.secondary
											: AppColors.textMuted,
										fontSize: 14,
										fontWeight: FontWeight.w500,
									),
								),
							],
						),
					),
					const SizedBox(width: 12),
					SizedBox(
						width: 112,
						child: SparklineChart(values: stats.sparklineValues),
					),
				],
			),
		);
	}
}

class DashboardStatCard extends StatelessWidget {
	const DashboardStatCard({
		super.key,
		required this.title,
		required this.value,
		required this.trendLabel,
		required this.trendPositive,
	});

	final String title;
	final String value;
	final String trendLabel;
	final bool trendPositive;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					Text(
						title,
						textAlign: TextAlign.center,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
							height: 1.3,
						),
					),
					const SizedBox(height: 12),
					Text(
						value,
						textAlign: TextAlign.center,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 28,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 8),
					Text(
						trendLabel,
						textAlign: TextAlign.center,
						style: TextStyle(
							color: trendPositive ? AppColors.secondary : AppColors.textMuted,
							fontSize: 13,
							fontWeight: FontWeight.w500,
						),
					),
				],
			),
		);
	}
}
