import 'package:flutter/material.dart';

import '../../models/tariff_plan.dart';
import '../../theme/app_theme.dart';

class TariffSegmentSwitch extends StatelessWidget {
	const TariffSegmentSwitch({
		super.key,
		required this.selectedAudience,
		required this.onAudienceChanged,
	});

	final TariffAudience selectedAudience;
	final ValueChanged<TariffAudience> onAudienceChanged;

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
						label: 'Для мастеров',
						audience: TariffAudience.masters,
					),
					_buildItem(
						label: 'Для студий',
						audience: TariffAudience.studios,
					),
				],
			),
		);
	}

	Widget _buildItem({
		required String label,
		required TariffAudience audience,
	}) {
		final isSelected = selectedAudience == audience;

		return Expanded(
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					onTap: () => onAudienceChanged(audience),
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
