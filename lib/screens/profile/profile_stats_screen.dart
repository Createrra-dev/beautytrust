import 'package:flutter/material.dart';

import '../../models/profile_stats.dart';
import '../../services/api/app_api_repository.dart';
import '../../theme/app_theme.dart';

class ProfileStatsScreen extends StatefulWidget {
	const ProfileStatsScreen({super.key});

	static const routeName = '/profile-stats';

	@override
	State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
	final _api = AppApiRepository();
	ProfileStats? _stats;
	var _isLoading = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_isLoading = true;
			_error = null;
		});

		try {
			final stats = await _api.fetchProfileStats();
			if (!mounted) {
				return;
			}
			setState(() {
				_stats = stats;
				_isLoading = false;
			});
		} catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_error = error.toString();
				_isLoading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
						child: Row(
							children: [
								IconButton(
									onPressed: () => Navigator.of(context).pop(),
									icon: const Icon(Icons.arrow_back_ios_new_rounded),
								),
								const Expanded(
									child: Text(
										'Статистика',
										textAlign: TextAlign.center,
										style: TextStyle(
											fontSize: 18,
											fontWeight: FontWeight.w600,
										),
									),
								),
								const SizedBox(width: 48),
							],
						),
					),
					Expanded(
						child: _isLoading
							? const Center(child: CircularProgressIndicator())
							: _error != null
								? Center(
									child: Padding(
										padding: const EdgeInsets.all(24),
										child: Text(
											_error!,
											textAlign: TextAlign.center,
											style: const TextStyle(color: AppColors.error),
										),
									),
								)
								: RefreshIndicator(
									onRefresh: _load,
									child: ListView(
										padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
										children: [
											_StatsSection(
												title: 'Записи',
												items: [
													_StatItem('Всего', '${_stats!.appointmentsTotal}'),
													_StatItem('Запланировано', '${_stats!.appointmentsScheduled}'),
													_StatItem('Завершено', '${_stats!.appointmentsCompleted}'),
													_StatItem('Неявки', '${_stats!.appointmentsNoShow}'),
													_StatItem('Отменено', '${_stats!.appointmentsCancelled}'),
													_StatItem(
														'Доля завершённых',
														'${_stats!.completionRate.toStringAsFixed(1)}%',
													),
												],
											),
											const SizedBox(height: 16),
											_StatsSection(
												title: 'Клиенты и проверки',
												items: [
													_StatItem(
														'Средний рейтинг клиентов',
														_stats!.avgClientRating.toStringAsFixed(1),
													),
													_StatItem('Проверок выполнено', '${_stats!.checksTotal}'),
													_StatItem('Отзывов оставлено', '${_stats!.reviewsGiven}'),
												],
											),
										],
									),
								),
					),
				],
			),
		);
	}
}

class _StatsSection extends StatelessWidget {
	const _StatsSection({
		required this.title,
		required this.items,
	});

	final String title;
	final List<_StatItem> items;

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
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Text(
						title,
						style: const TextStyle(
							fontSize: 16,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 12),
					for (var index = 0; index < items.length; index++) ...[
						if (index > 0) const Divider(color: AppColors.border, height: 16),
						Row(
							children: [
								Expanded(
									child: Text(
										items[index].label,
										style: const TextStyle(
											color: AppColors.textMuted,
											fontSize: 14,
										),
									),
								),
								Text(
									items[index].value,
									style: const TextStyle(
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
							],
						),
					],
				],
			),
		);
	}
}

class _StatItem {
	const _StatItem(this.label, this.value);

	final String label;
	final String value;
}
