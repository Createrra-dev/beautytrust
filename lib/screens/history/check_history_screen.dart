import 'package:flutter/material.dart';

import '../../models/check_history_record.dart';
import '../../services/api/beauty_trust_api.dart';
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
	var _isLoading = true;
	List<CheckHistoryRecord> _checks = [];

	@override
	void initState() {
		super.initState();
		_loadChecks();
	}

	Future<void> _loadChecks() async {
		setState(() => _isLoading = true);
		try {
			final checks = await CheckHistoryDataService.checksFor(_selectedFilter);
			if (!mounted) {
				return;
			}
			setState(() {
				_checks = checks;
				_isLoading = false;
			});
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() => _isLoading = false);
			AppSnackBar.show(context, error.message, type: AppSnackBarType.error);
		}
	}

	@override
	Widget build(BuildContext context) {
		final referenceNow = DateTime.now();

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
								_loadChecks();
							},
						),
					),
					Expanded(
						child: _isLoading
							? const Center(child: CircularProgressIndicator())
							: _checks.isEmpty
								? const _EmptyState()
								: ListView.separated(
									padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
									itemCount: _checks.length,
									separatorBuilder: (context, index) =>
										const SizedBox(height: 8),
									itemBuilder: (context, index) {
										return CheckHistoryCard(
											record: _checks[index],
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
				'Пока нет проверок',
				style: TextStyle(color: AppColors.textMuted, fontSize: 15),
			),
		);
	}
}
