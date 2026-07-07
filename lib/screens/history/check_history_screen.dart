import 'package:flutter/material.dart';

import '../../models/check_history_record.dart';
import '../../services/check_history_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/history/check_history_card.dart';
import '../../widgets/history/check_history_filter_bar.dart';

class CheckHistoryScreen extends StatefulWidget {
	const CheckHistoryScreen({super.key});

	@override
	State<CheckHistoryScreen> createState() => _CheckHistoryScreenState();
}

class _CheckHistoryScreenState extends State<CheckHistoryScreen> {
	var _selectedFilter = CheckHistoryFilter.all;

	@override
	Widget build(BuildContext context) {
		final referenceNow = DateTime.now();
		final checks = CheckHistoryDataService.checksFor(
			_selectedFilter,
			referenceNow: referenceNow,
		);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					const _CheckHistoryHeader(),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
						child: CheckHistoryFilterBar(
							selectedFilter: _selectedFilter,
							onFilterSelected: (filter) {
								setState(() => _selectedFilter = filter);
							},
						),
					),
					Expanded(
						child: checks.isEmpty
							? const _EmptyState()
							: ListView.separated(
								padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
								itemCount: checks.length,
								separatorBuilder: (context, index) =>
									const SizedBox(height: 8),
								itemBuilder: (context, index) {
									return CheckHistoryCard(
										record: checks[index],
										referenceNow: referenceNow,
									);
								},
							),
					),
				],
			),
		);
	}
}

class _CheckHistoryHeader extends StatelessWidget {
	const _CheckHistoryHeader();

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
			child: Row(
				children: [
					const SizedBox(width: 48),
					const Expanded(
						child: Text(
							'История проверок',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 18,
								fontWeight: FontWeight.w600,
							),
						),
					),
					IconButton(
						onPressed: () {
							AppSnackBar.show(
								context,
								'Уведомления скоро будут доступны',
							);
						},
						icon: const Icon(
							Icons.notifications_none_rounded,
							color: AppColors.textPrimary,
						),
					),
				],
			),
		);
	}
}

class _EmptyState extends StatelessWidget {
	const _EmptyState();

	@override
	Widget build(BuildContext context) {
		return const Center(
			child: Text(
				'Проверок по выбранному фильтру нет',
				style: TextStyle(
					color: AppColors.textMuted,
					fontSize: 15,
				),
			),
		);
	}
}
