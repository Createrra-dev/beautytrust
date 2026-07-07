import 'package:flutter/material.dart';

import '../../models/dashboard_period.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';

Future<DashboardPeriod?> showPeriodPickerSheet(
	BuildContext context, {
	required DashboardPeriod selectedPeriod,
}) {
	return showModalBottomSheet<DashboardPeriod>(
		context: context,
		backgroundColor: AppColors.surfaceElevated,
		shape: const RoundedRectangleBorder(
			borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
		),
		builder: (context) {
			return _PeriodPickerSheet(selectedPeriod: selectedPeriod);
		},
	);
}

class _PeriodPickerSheet extends StatelessWidget {
	const _PeriodPickerSheet({required this.selectedPeriod});

	final DashboardPeriod selectedPeriod;

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					const SizedBox(height: 12),
					Container(
						width: 40,
						height: 4,
						decoration: BoxDecoration(
							color: AppColors.border,
							borderRadius: BorderRadius.circular(2),
						),
					),
					const SizedBox(height: 16),
					const Text(
						'Выберите период',
						style: TextStyle(
							color: AppColors.textPrimary,
							fontSize: 18,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 12),
					Flexible(
						child: ListView.separated(
							shrinkWrap: true,
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
							itemCount: DashboardDataService.availablePeriods.length,
							separatorBuilder: (context, index) => const SizedBox(height: 8),
							itemBuilder: (context, index) {
								final period = DashboardDataService.availablePeriods[index];
								final isSelected = period.year == selectedPeriod.year &&
									period.month == selectedPeriod.month;

								return Material(
									color: isSelected ? AppColors.surface : Colors.transparent,
									borderRadius: BorderRadius.circular(12),
									child: InkWell(
										onTap: () => Navigator.of(context).pop(period),
										borderRadius: BorderRadius.circular(12),
										child: Container(
											padding: const EdgeInsets.symmetric(
												horizontal: 16,
												vertical: 14,
											),
											decoration: BoxDecoration(
												borderRadius: BorderRadius.circular(12),
												border: Border.all(
													color: isSelected
														? AppColors.primary
														: AppColors.border,
												),
											),
											child: Row(
												children: [
													Expanded(
														child: Text(
															period.label,
															style: TextStyle(
																color: isSelected
																	? AppColors.textPrimary
																	: AppColors.textMuted,
																fontSize: 16,
																fontWeight: isSelected
																	? FontWeight.w600
																	: FontWeight.w500,
															),
														),
													),
													if (isSelected)
														const Icon(
															Icons.check_rounded,
															color: AppColors.primary,
															size: 20,
														),
												],
											),
										),
									),
								);
							},
						),
					),
				],
			),
		);
	}
}
