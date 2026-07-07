import 'package:flutter/material.dart';

import '../../models/dashboard_period.dart';
import '../../services/dashboard_data_service.dart';
import '../../widgets/home/current_appointments_section.dart';
import '../../widgets/home/dashboard_top_section.dart';
import '../../widgets/home/home_quick_phone_check.dart';
import '../../widgets/home/period_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
	const HomeScreen({super.key});

	@override
	State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
	late DashboardPeriod _selectedPeriod;
	final _dashboardService = DashboardDataService.instance;

	@override
	void initState() {
		super.initState();
		_selectedPeriod = DashboardDataService.defaultPeriod;
		_dashboardService.addListener(_onDashboardChanged);
	}

	@override
	void dispose() {
		_dashboardService.removeListener(_onDashboardChanged);
		super.dispose();
	}

	void _onDashboardChanged() {
		setState(() {});
	}

	Future<void> _openPeriodPicker() async {
		final selectedPeriod = await showPeriodPickerSheet(
			context,
			selectedPeriod: _selectedPeriod,
		);

		if (selectedPeriod == null || !mounted) {
			return;
		}

		setState(() => _selectedPeriod = selectedPeriod);
	}

	@override
	Widget build(BuildContext context) {
		final stats = DashboardDataService.statsFor(_selectedPeriod);
		final appointments = DashboardDataService.currentAppointments();

		return SafeArea(
			child: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						DashboardTopSection(
							stats: stats,
							onPeriodTap: _openPeriodPicker,
						),
						const SizedBox(height: 12),
						const HomeQuickPhoneCheck(),
						const SizedBox(height: 28),
						CurrentAppointmentsSection(appointments: appointments),
					],
				),
			),
		);
	}
}
