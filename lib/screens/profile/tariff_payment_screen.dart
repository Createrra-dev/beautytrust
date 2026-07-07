import 'package:flutter/material.dart';

import '../../models/tariff_plan.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
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
	var _selectedPeriod = '1 месяц';
	var _selectedCardIndex = 0;

	static const _periods = [
		'1 месяц',
		'3 месяца',
		'12 месяцев',
	];

	static const _cards = [
		('VISA', '•••• 4242'),
		('MC', '•••• 8811'),
		('МИР', '•••• 1209'),
	];

	@override
	Widget build(BuildContext context) {
		final plan = widget.plan;

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						onBack: () => Navigator.of(context).pop(),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Container(
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(
											color: AppColors.surface,
											borderRadius: BorderRadius.circular(14),
											border: Border.all(color: AppColors.border),
										),
										child: Row(
											children: [
												const AppLogo(size: 40),
												const SizedBox(width: 12),
												Expanded(
													child: Column(
														crossAxisAlignment:
															CrossAxisAlignment.start,
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
																	color: AppColors.textMuted,
																	fontSize: 13,
																),
															),
														],
													),
												),
											],
										),
									),
									const SizedBox(height: 20),
									const Text(
										'Период подписки',
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 14,
										),
									),
									const SizedBox(height: 8),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 14),
										decoration: BoxDecoration(
											color: AppColors.surface,
											borderRadius: BorderRadius.circular(12),
											border: Border.all(color: AppColors.border),
										),
										child: DropdownButtonHideUnderline(
											child: DropdownButton<String>(
												value: _selectedPeriod,
												isExpanded: true,
												dropdownColor: AppColors.surfaceElevated,
												style: const TextStyle(
													color: AppColors.textPrimary,
													fontSize: 16,
												),
												items: _periods
													.map(
														(period) => DropdownMenuItem(
															value: period,
															child: Text(period),
														),
													)
													.toList(),
												onChanged: (value) {
													if (value == null) {
														return;
													}

													setState(() => _selectedPeriod = value);
												},
											),
										),
									),
									const SizedBox(height: 20),
									const Text(
										'Способ оплаты',
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 14,
										),
									),
									const SizedBox(height: 8),
									...List.generate(_cards.length, (index) {
										final card = _cards[index];
										final isSelected = _selectedCardIndex == index;

										return Padding(
											padding: const EdgeInsets.only(bottom: 8),
											child: Material(
												color: AppColors.surface,
												borderRadius: BorderRadius.circular(12),
												child: InkWell(
													onTap: () {
														setState(() => _selectedCardIndex = index);
													},
													borderRadius: BorderRadius.circular(12),
													child: Ink(
														decoration: BoxDecoration(
															borderRadius: BorderRadius.circular(12),
															border: Border.all(
																color: isSelected
																	? AppColors.primary
																	: AppColors.border,
															),
														),
														child: Padding(
															padding: const EdgeInsets.all(14),
															child: Row(
																children: [
																	Container(
																		padding:
																			const EdgeInsets.symmetric(
																				horizontal: 8,
																				vertical: 4,
																			),
																		decoration: BoxDecoration(
																			color: AppColors
																				.surfaceElevated,
																			borderRadius:
																				BorderRadius.circular(
																					6,
																				),
																		),
																		child: Text(
																			card.$1,
																			style: const TextStyle(
																				color: AppColors
																					.textMuted,
																				fontSize: 11,
																				fontWeight:
																					FontWeight.w600,
																			),
																		),
																	),
																	const SizedBox(width: 12),
																	Expanded(
																		child: Text(
																			card.$2,
																			style: const TextStyle(
																				color: AppColors
																					.textPrimary,
																				fontSize: 15,
																				fontWeight:
																					FontWeight.w500,
																			),
																		),
																	),
																	if (isSelected)
																		const Icon(
																			Icons
																				.check_circle_rounded,
																			color: AppColors.primary,
																			size: 20,
																		),
																],
															),
														),
													),
												),
											),
										);
									}),
									const SizedBox(height: 24),
									FilledButton(
										onPressed: _pay,
										child: Text('Оплатить ${plan.monthlyPrice} ₽'),
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

	void _pay() {
		Navigator.of(context).pushNamedAndRemoveUntil(
			TariffSuccessScreen.routeName,
			(route) => route.isFirst,
			arguments: widget.plan,
		);
	}
}

class _PageHeader extends StatelessWidget {
	const _PageHeader({required this.onBack});

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
