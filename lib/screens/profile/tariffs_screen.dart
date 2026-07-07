import 'package:flutter/material.dart';

import '../../data/tariff_plans_data.dart';
import '../../models/tariff_plan.dart';
import '../../services/tariff_pricing_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile/tariff_plan_card.dart';
import '../../widgets/profile/tariff_segment_switch.dart';
import 'tariff_detail_screen.dart';
import 'tariff_success_screen.dart';

class TariffsScreen extends StatefulWidget {
	const TariffsScreen({super.key});

	static const routeName = '/tariffs';

	@override
	State<TariffsScreen> createState() => _TariffsScreenState();
}

class _TariffsScreenState extends State<TariffsScreen> {
	var _selectedAudience = TariffAudience.masters;

	@override
	Widget build(BuildContext context) {
		final plans = TariffPlansData.plansFor(_selectedAudience);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Тарифы',
						onBack: () => Navigator.of(context).pop(),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
						child: TariffSegmentSwitch(
							selectedAudience: _selectedAudience,
							onAudienceChanged: (audience) {
								setState(() => _selectedAudience = audience);
							},
						),
					),
					Expanded(
						child: ListView.separated(
							padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
							itemCount: plans.length,
							separatorBuilder: (context, index) =>
								const SizedBox(height: 12),
							itemBuilder: (context, index) {
								final plan = plans[index];

								return TariffPlanCard(
									plan: plan,
									onButtonPressed: () => _onPlanSelected(plan),
								);
							},
						),
					),
				],
			),
		);
	}

	void _onPlanSelected(TariffPlan plan) {
		if (plan.monthlyPrice == 0) {
			Navigator.of(context).pushNamed(
				TariffSuccessScreen.routeName,
				arguments: TariffPricingService.buildSummary(
					plan: plan,
					months: 1,
				),
			);
			return;
		}

		Navigator.of(context).pushNamed(
			TariffDetailScreen.routeName,
			arguments: plan,
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
