import 'package:flutter/material.dart';

import '../../models/check_history_record.dart';
import '../../theme/app_theme.dart';

class CheckHistoryFilterBar extends StatelessWidget {
	const CheckHistoryFilterBar({
		super.key,
		required this.selectedFilter,
		required this.onFilterSelected,
	});

	final CheckHistoryFilter selectedFilter;
	final ValueChanged<CheckHistoryFilter> onFilterSelected;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(4),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				children: [
					_buildItem(
						label: 'Все',
						filter: CheckHistoryFilter.all,
					),
					_buildItem(
						label: 'Надёжные',
						filter: CheckHistoryFilter.reliable,
					),
					_buildItem(
						label: 'Рискованные',
						filter: CheckHistoryFilter.risky,
					),
				],
			),
		);
	}

	Widget _buildItem({
		required String label,
		required CheckHistoryFilter filter,
	}) {
		final isSelected = selectedFilter == filter;

		return Expanded(
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					onTap: () => onFilterSelected(filter),
					borderRadius: BorderRadius.circular(10),
					child: AnimatedContainer(
						duration: const Duration(milliseconds: 200),
						padding: const EdgeInsets.symmetric(vertical: 10),
						decoration: BoxDecoration(
							color: isSelected
								? AppColors.surfaceElevated
								: Colors.transparent,
							borderRadius: BorderRadius.circular(10),
							border: isSelected
								? Border.all(
									color: AppColors.primary.withValues(alpha: 0.45),
								)
								: null,
							boxShadow: isSelected
								? [
									BoxShadow(
										color: AppColors.primary.withValues(alpha: 0.12),
										blurRadius: 8,
									),
								]
								: null,
						),
						child: Text(
							label,
							textAlign: TextAlign.center,
							style: TextStyle(
								color: isSelected
									? AppColors.textPrimary
									: AppColors.textMuted,
								fontSize: 13,
								fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
							),
						),
					),
				),
			),
		);
	}
}
