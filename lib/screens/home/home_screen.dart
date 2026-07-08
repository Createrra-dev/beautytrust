import 'package:flutter/material.dart';

import '../../models/dashboard_period.dart';
import '../../models/dashboard_stats.dart';
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
	DashboardStats? _stats;
	var _isLoadingStats = true;

	@override
	void initState() {
		super.initState();
		_selectedPeriod = DashboardDataService.defaultPeriod;
		_dashboardService.addListener(_onDashboardChanged);
		_bootstrap();
	}

	@override
	void dispose() {
		_dashboardService.removeListener(_onDashboardChanged);
		super.dispose();
	}

	Future<void> _bootstrap() async {
		await DashboardDataService.syncFromApi();
		if (!mounted) {
			return;
		}
		setState(() {
			_selectedPeriod = DashboardDataService.defaultPeriod;
		});
		await _loadStats();
	}

	void _onDashboardChanged() {
		_loadStats();
		setState(() {});
	}

	Future<void> _loadStats() async {
		setState(() => _isLoadingStats = true);
		final stats = await DashboardDataService.statsFor(_selectedPeriod);
		if (!mounted) {
			return;
		}
		setState(() {
			_stats = stats;
			_isLoadingStats = false;
		});
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
		await _loadStats();
	}

	@override
	Widget build(BuildContext context) {
		final appointments = DashboardDataService.currentAppointments();
		final stats = _stats;

		return SafeArea(
			child: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						if (_isLoadingStats || stats == null)
							const Padding(
								padding: EdgeInsets.symmetric(vertical: 24),
								child: Center(child: CircularProgressIndicator()),
							)
						else
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
