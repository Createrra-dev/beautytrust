import 'package:flutter/material.dart';

import '../../data/tariff_plans_data.dart';
import '../../models/tariff_plan.dart';
import '../../services/api/app_api_repository.dart';
import '../../services/api/beauty_trust_api.dart';
import '../../services/tariff_pricing_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/profile/tariff_plan_card.dart';
import '../../widgets/profile/tariff_segment_switch.dart';
import 'tariff_payment_screen.dart';
import 'tariff_success_screen.dart';

class TariffsScreen extends StatefulWidget {
	const TariffsScreen({super.key});

	static const routeName = '/tariffs';

	@override
	State<TariffsScreen> createState() => _TariffsScreenState();
}

class _TariffsScreenState extends State<TariffsScreen> {
	final _api = AppApiRepository();
	var _selectedAudience = TariffAudience.masters;
	List<TariffPlan> _plans = [];
	MasterSubscription? _subscription;
	var _isLoading = true;
	var _isActivatingFree = false;
	String? _errorText;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_isLoading = true;
			_errorText = null;
		});

		try {
			final plans = await TariffPlansData.load(audience: _selectedAudience);
			MasterSubscription? subscription;
			try {
				subscription = await _api.fetchSubscription();
			} on ApiException {
				subscription = null;
			}
			if (!mounted) {
				return;
			}
			setState(() {
				_plans = plans;
				_subscription = subscription;
				_isLoading = false;
			});
		} catch (_) {
			if (!mounted) {
				return;
			}
			setState(() {
				_plans = TariffPlansData.plansFor(_selectedAudience);
				_isLoading = false;
				_errorText = 'Не удалось загрузить тарифы';
			});
		}
	}

	Future<void> _onAudienceChanged(TariffAudience audience) async {
		setState(() => _selectedAudience = audience);
		final plans = await TariffPlansData.load(audience: audience);
		if (!mounted) {
			return;
		}
		setState(() => _plans = plans);
	}

	Future<void> _onPlanSelected(TariffPlan plan) async {
		if (plan.monthlyPrice == 0) {
			setState(() => _isActivatingFree = true);
			try {
				final result = await _api.subscribeToPlan(planId: plan.id, months: 1);
				if (!mounted) {
					return;
				}
				if (!result.activated) {
					AppSnackBar.show(
						context,
						'Не удалось активировать бесплатный тариф',
						type: AppSnackBarType.error,
					);
					return;
				}
				Navigator.of(context).pushNamed(
					TariffSuccessScreen.routeName,
					arguments: TariffPricingService.buildSummary(
						plan: plan,
						months: 1,
					),
				);
			} on ApiException catch (error) {
				if (!mounted) {
					return;
				}
				AppSnackBar.show(context, error.message, type: AppSnackBarType.error);
			} finally {
				if (mounted) {
					setState(() => _isActivatingFree = false);
				}
			}
			return;
		}

		Navigator.of(context).pushNamed(
			TariffPaymentScreen.routeName,
			arguments: plan,
		);
	}

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Тарифы',
						onBack: () => Navigator.of(context).pop(),
					),
					if (_subscription != null)
						Padding(
							padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
							child: _CurrentSubscriptionBanner(subscription: _subscription!),
						),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
						child: TariffSegmentSwitch(
							selectedAudience: _selectedAudience,
							onAudienceChanged: _isActivatingFree ? (_) {} : _onAudienceChanged,
						),
					),
					Expanded(
						child: _isLoading
							? const Center(child: CircularProgressIndicator())
							: RefreshIndicator(
								onRefresh: _load,
								child: ListView.separated(
									physics: const AlwaysScrollableScrollPhysics(),
									padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
									itemCount: _plans.length + (_errorText == null ? 0 : 1),
									separatorBuilder: (context, index) => const SizedBox(height: 12),
									itemBuilder: (context, index) {
										if (_errorText != null && index == 0) {
											return Text(
												_errorText!,
												textAlign: TextAlign.center,
												style: const TextStyle(color: AppColors.error),
											);
										}
										final planIndex = _errorText == null ? index : index - 1;
										final plan = _plans[planIndex];
										return TariffPlanCard(
											plan: plan,
											onButtonPressed: _isActivatingFree
												? () {}
												: () => _onPlanSelected(plan),
										);
									},
								),
							),
					),
				],
			),
		);
	}
}

class _CurrentSubscriptionBanner extends StatelessWidget {
	const _CurrentSubscriptionBanner({required this.subscription});

	final MasterSubscription subscription;

	@override
	Widget build(BuildContext context) {
		final expires = subscription.expiresAt;
		final expiresLabel = expires == null
			? 'без срока'
			: 'до ${expires.day.toString().padLeft(2, '0')}.'
				'${expires.month.toString().padLeft(2, '0')}.'
				'${expires.year}';

		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				children: [
					const Icon(Icons.workspace_premium_outlined, color: AppColors.secondary),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Сейчас: ${subscription.tariffLabel}',
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 2),
								Text(
									subscription.isActive ? 'Активен $expiresLabel' : 'Истёк $expiresLabel',
									style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
								),
							],
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
