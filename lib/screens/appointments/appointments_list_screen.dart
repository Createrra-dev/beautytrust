import 'package:flutter/material.dart';

import '../../models/appointment_time_filter.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/appointment_card.dart';
import '../../widgets/home/appointment_filter_bar.dart';

class AppointmentsListScreen extends StatefulWidget {
	const AppointmentsListScreen({super.key});

	static const routeName = '/appointments';

	@override
	State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
	var _selectedFilter = AppointmentTimeFilter.all;

	@override
	void initState() {
		super.initState();
		DashboardDataService.instance.addListener(_onDashboardChanged);
	}

	@override
	void dispose() {
		DashboardDataService.instance.removeListener(_onDashboardChanged);
		super.dispose();
	}

	void _onDashboardChanged() {
		if (mounted) {
			setState(() {});
		}
	}

	@override
	Widget build(BuildContext context) {
		final referenceNow = DateTime.now();
		final appointments = DashboardDataService.appointmentsFor(
			_selectedFilter,
			referenceNow: referenceNow,
		);

		return Scaffold(
			body: SafeArea(
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
							child: Row(
								children: [
									IconButton(
										onPressed: () => Navigator.of(context).pop(),
										icon: const Icon(
											Icons.arrow_back_rounded,
											color: AppColors.textPrimary,
										),
									),
									const Expanded(
										child: Text(
											'Записи',
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
						),
						Padding(
							padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
							child: AppointmentFilterBar(
								selectedFilter: _selectedFilter,
								onFilterSelected: (filter) {
									setState(() => _selectedFilter = filter);
								},
							),
						),
						Expanded(
							child: appointments.isEmpty
								? _EmptyState(filter: _selectedFilter)
								: ListView.separated(
									padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
									itemCount: appointments.length,
									separatorBuilder: (context, index) =>
										const SizedBox(height: 8),
									itemBuilder: (context, index) {
										return AppointmentCard(
											appointment: appointments[index],
										);
									},
								),
						),
					],
				),
			),
		);
	}
}

class _EmptyState extends StatelessWidget {
	const _EmptyState({required this.filter});

	final AppointmentTimeFilter filter;

	@override
	Widget build(BuildContext context) {
		final message = switch (filter) {
			AppointmentTimeFilter.all => 'Пока нет записей',
			AppointmentTimeFilter.past => 'Нет прошедших записей',
			AppointmentTimeFilter.active => 'Нет активных записей',
		};

		return Center(
			child: Text(
				message,
				style: const TextStyle(
					color: AppColors.textMuted,
					fontSize: 15,
				),
			),
		);
	}
}
