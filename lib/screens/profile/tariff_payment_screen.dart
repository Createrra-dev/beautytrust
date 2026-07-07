import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/appointment_record.dart';
import '../../models/tariff_payment_summary.dart';
import '../../models/tariff_plan.dart';
import '../../services/payment_api.dart';
import '../../services/tariff_pricing_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../payment_webview_screen.dart';
import 'tariff_success_screen.dart';

class TariffPaymentScreen extends StatefulWidget {
	const TariffPaymentScreen({
		super.key,
		required this.plan,
	});

	static const routeName = '/tariff-payment';

	final TariffPlan plan;

	@override
	State<TariffPaymentScreen> createState() => _TariffPaymentScreenState();
}

class _TariffPaymentScreenState extends State<TariffPaymentScreen> {
	final PaymentApi _paymentApi = PaymentApi();
	var _selectedMonths = TariffSubscriptionPeriod.options.first.months;
	var _isPaying = false;
	String? _errorText;

	TariffPaymentSummary get _summary => TariffPricingService.buildSummary(
		plan: widget.plan,
		months: _selectedMonths,
	);

	@override
	Widget build(BuildContext context) {
		final summary = _summary;
		final selectedPeriod = TariffSubscriptionPeriod.options.firstWhere(
			(period) => period.months == _selectedMonths,
		);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						onBack: _isPaying ? null : () => Navigator.of(context).pop(),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									_TariffSummaryCard(plan: widget.plan),
									const SizedBox(height: 12),
									_PeriodSelectorCard(
										selectedLabel: selectedPeriod.label,
										onTap: _isPaying ? null : _openPeriodPicker,
									),
									const SizedBox(height: 16),
									_PriceBreakdownCard(summary: summary),
									if (_errorText != null) ...[
										const SizedBox(height: 12),
										Text(
											_errorText!,
											textAlign: TextAlign.center,
											style: const TextStyle(
												color: AppColors.error,
												fontSize: 13,
											),
										),
									],
									const SizedBox(height: 24),
									FilledButton(
										onPressed: _isPaying ? null : _pay,
										style: FilledButton.styleFrom(
											padding: const EdgeInsets.symmetric(vertical: 16),
										),
										child: _isPaying
											? const SizedBox(
												width: 22,
												height: 22,
												child: CircularProgressIndicator(
													strokeWidth: 2,
													color: AppColors.textPrimary,
												),
											)
											: Text(
												'Оплатить ${formatServicePrice(summary.totalRubles)}',
											),
									),
									const SizedBox(height: 12),
									const Text(
										'Нажимая «Оплатить», вы соглашаетесь с офертой и подпиской',
										textAlign: TextAlign.center,
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 12,
											height: 1.4,
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}

	Future<void> _openPeriodPicker() async {
		final selected = await showModalBottomSheet<int>(
			context: context,
			backgroundColor: AppColors.surfaceElevated,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) {
				return SafeArea(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const Padding(
								padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
								child: Text(
									'Период подписки',
									style: TextStyle(
										color: AppColors.textPrimary,
										fontSize: 18,
										fontWeight: FontWeight.w600,
									),
								),
							),
							...TariffSubscriptionPeriod.options.map((period) {
								final quote = TariffPricingService.quote(
									monthlyPriceRubles: widget.plan.monthlyPrice,
									months: period.months,
								);
								final discountLabel = quote.discountPercent > 0
									? ' · скидка ${quote.discountPercent}%'
									: '';

								return ListTile(
									title: Text(
										period.label,
										style: const TextStyle(color: AppColors.textPrimary),
									),
									subtitle: Text(
										'${formatServicePrice(quote.totalRubles)}$discountLabel',
										style: const TextStyle(color: AppColors.textMuted),
									),
									trailing: _selectedMonths == period.months
										? const Icon(
											Icons.check_rounded,
											color: AppColors.primary,
										)
										: null,
									onTap: () => Navigator.of(context).pop(period.months),
								);
							}),
							const SizedBox(height: 8),
						],
					),
				);
			},
		);

		if (selected == null || !mounted) {
			return;
		}

		setState(() {
			_selectedMonths = selected;
			_errorText = null;
		});
	}

	Future<void> _pay() async {
		final summary = _summary;

		setState(() {
			_isPaying = true;
			_errorText = null;
		});

		try {
			final initResult = await _paymentApi.initPayment(
				amountKopecks: summary.amountKopecks,
				description: summary.description,
				returnBaseUrl: AppConfig.apiBaseUrl,
			);

			if (!mounted) {
				return;
			}

			final webViewResult = await Navigator.of(context).push<PaymentWebViewResult>(
				MaterialPageRoute(
					builder: (context) => PaymentWebViewScreen(
						paymentUrl: initResult.paymentUrl,
					),
				),
			);

			if (!mounted) {
				return;
			}

			if (webViewResult == PaymentWebViewResult.cancelled) {
				setState(() {
					_errorText = 'Оплата отменена';
				});
				return;
			}

			final statusResult =
				await _paymentApi.getPaymentStatus(initResult.paymentId);

			if (!mounted) {
				return;
			}

			if (!statusResult.success) {
				setState(() {
					_errorText = 'Оплата не выполнена (${statusResult.status})';
				});
				return;
			}

			Navigator.of(context).pushNamedAndRemoveUntil(
				TariffSuccessScreen.routeName,
				(route) => route.isFirst,
				arguments: summary,
			);
		} on PaymentApiException catch (error) {
			if (!mounted) {
				return;
			}

			setState(() {
				_errorText = error.message;
			});
		} catch (error) {
			if (!mounted) {
				return;
			}

			setState(() {
				_errorText = error.toString();
			});
		} finally {
			if (mounted) {
				setState(() {
					_isPaying = false;
				});
			}
		}
	}
}

class _TariffSummaryCard extends StatelessWidget {
	const _TariffSummaryCard({required this.plan});

	final TariffPlan plan;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				children: [
					const AppLogo(size: 44),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Тариф ${plan.title}',
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 4),
								Text(
									plan.priceLabel,
									style: const TextStyle(
										color: AppColors.primary,
										fontSize: 14,
										fontWeight: FontWeight.w600,
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

class _PeriodSelectorCard extends StatelessWidget {
	const _PeriodSelectorCard({
		required this.selectedLabel,
		required this.onTap,
	});

	final String selectedLabel;
	final VoidCallback? onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.surface,
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(14),
				child: Ink(
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: AppColors.border),
					),
					child: Padding(
						padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
						child: Row(
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text(
												'Период подписки',
												style: TextStyle(
													color: AppColors.textMuted,
													fontSize: 13,
												),
											),
											const SizedBox(height: 4),
											Text(
												selectedLabel,
												style: const TextStyle(
													color: AppColors.textPrimary,
													fontSize: 16,
													fontWeight: FontWeight.w600,
												),
											),
										],
									),
								),
								const Icon(
									Icons.keyboard_arrow_down_rounded,
									color: AppColors.textMuted,
								),
							],
						),
					),
				),
			),
		);
	}
}

class _PriceBreakdownCard extends StatelessWidget {
	const _PriceBreakdownCard({required this.summary});

	final TariffPaymentSummary summary;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				children: [
					_PriceRow(
						label: 'Стоимость без скидки',
						value: formatServicePrice(summary.baseTotalRubles),
					),
					if (summary.discountPercent > 0) ...[
						const SizedBox(height: 10),
						_PriceRow(
							label: 'Скидка ${summary.discountPercent}%',
							value: '−${formatServicePrice(summary.savedRubles)}',
							valueColor: AppColors.secondary,
						),
					],
					const SizedBox(height: 10),
					const Divider(color: AppColors.border, height: 1),
					const SizedBox(height: 10),
					_PriceRow(
						label: 'К оплате',
						value: formatServicePrice(summary.totalRubles),
						labelStyle: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 15,
							fontWeight: FontWeight.w600,
						),
						valueStyle: const TextStyle(
							color: AppColors.primary,
							fontSize: 18,
							fontWeight: FontWeight.w700,
						),
					),
				],
			),
		);
	}
}

class _PriceRow extends StatelessWidget {
	const _PriceRow({
		required this.label,
		required this.value,
		this.valueColor,
		this.labelStyle,
		this.valueStyle,
	});

	final String label;
	final String value;
	final Color? valueColor;
	final TextStyle? labelStyle;
	final TextStyle? valueStyle;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Expanded(
					child: Text(
						label,
						style: labelStyle ??
							const TextStyle(
								color: AppColors.textMuted,
								fontSize: 14,
							),
					),
				),
				Text(
					value,
					style: valueStyle ??
						TextStyle(
							color: valueColor ?? AppColors.textPrimary,
							fontSize: 14,
							fontWeight: FontWeight.w600,
						),
				),
			],
		);
	}
}

class _PageHeader extends StatelessWidget {
	const _PageHeader({required this.onBack});

	final VoidCallback? onBack;

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
					const Expanded(
						child: Text(
							'Оплата',
							textAlign: TextAlign.center,
							style: TextStyle(
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
