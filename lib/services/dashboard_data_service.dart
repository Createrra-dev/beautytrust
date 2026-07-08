import 'package:flutter/foundation.dart';

import '../models/appointment_record.dart';
import '../models/dashboard_period.dart';
import '../models/dashboard_stats.dart';
import '../models/visit_result.dart';
import 'api/app_api_repository.dart';
import 'api/beauty_trust_api.dart';

class DashboardDataService extends ChangeNotifier {
	DashboardDataService._();

	static final DashboardDataService instance = DashboardDataService._();
	static final AppApiRepository _api = AppApiRepository();

	final List<AppointmentRecord> _appointments = [];
	List<DashboardPeriod> _periods = [];
	final Map<String, DashboardStats> _statsCache = {};
	DashboardPeriod? _defaultPeriod;

	static List<DashboardPeriod> get availablePeriods {
		if (instance._periods.isNotEmpty) {
			return List<DashboardPeriod>.from(instance._periods);
		}
		final now = DateTime.now();
		return [
			DashboardPeriod(year: now.year, month: now.month),
		];
	}

	static DashboardPeriod get defaultPeriod {
		return instance._defaultPeriod ?? availablePeriods.first;
	}

	static Future<DashboardStats> statsFor(DashboardPeriod period) async {
		final key = _periodKey(period);
		final cached = instance._statsCache[key];
		if (cached != null) {
			return cached;
		}

		try {
			final stats = await _api.fetchDashboardStats(
				year: period.year,
				month: period.month,
			);
			instance._statsCache[key] = stats;
			return stats;
		} on ApiException {
			return DashboardStats(
				periodLabel: period.label,
				protectedIncome: 0,
				incomeTrendLabel: 'нет данных',
				incomeTrendPositive: true,
				sparklineValues: const [0.2, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.7, 0.8, 0.9, 1.0],
				preventedNoShows: 0,
				noShowsTrendLabel: 'нет данных',
				completedChecks: 0,
				checksTrendLabel: 'нет данных',
			);
		}
	}

	static List<AppointmentRecord> currentAppointments() {
		return List<AppointmentRecord>.from(instance._appointments);
	}

	static Future<void> syncFromApi() async {
		final appointments = await _api.fetchAppointments();
		instance._appointments
			..clear()
			..addAll(appointments);

		try {
			final periods = await _api.fetchDashboardPeriods();
			if (periods.isNotEmpty) {
				instance._periods = periods;
				instance._defaultPeriod = periods.first;
			}
		} on ApiException {
			// Keep fallback periods.
		}

		instance._statsCache.clear();
		instance.notifyListeners();
	}

	static Future<void> addAppointment(AppointmentRecord appointment) async {
		final created = await _api.createAppointment(appointment);
		instance._appointments.insert(0, created);
		instance._statsCache.clear();
		instance.notifyListeners();
	}

	static Future<void> saveVisitResult(String appointmentId, VisitResult visitResult) async {
		final updated = await _api.saveVisitResult(appointmentId, visitResult);
		final appointmentIndex = instance._appointments.indexWhere(
			(appointment) => appointment.id == appointmentId,
		);
		if (appointmentIndex == -1) {
			instance._appointments.insert(0, updated);
		} else {
			instance._appointments[appointmentIndex] = updated;
		}
		instance._statsCache.clear();
		instance.notifyListeners();
	}

	static Future<void> updateAppointment(AppointmentRecord appointment) async {
		final updated = await _api.updateAppointment(appointment);
		final appointmentIndex = instance._appointments.indexWhere(
			(item) => item.id == appointment.id,
		);
		if (appointmentIndex == -1) {
			return;
		}
		instance._appointments[appointmentIndex] = updated;
		instance._statsCache.clear();
		instance.notifyListeners();
	}

	static Future<void> deleteAppointment(String appointmentId) async {
		await _api.deleteAppointment(appointmentId);
		instance._appointments.removeWhere((item) => item.id == appointmentId);
		instance._statsCache.clear();
		instance.notifyListeners();
	}

	static AppointmentRecord? appointmentById(String id) {
		for (final appointment in currentAppointments()) {
			if (appointment.id == id) {
				return appointment;
			}
		}

		return null;
	}

	static String _periodKey(DashboardPeriod period) {
		return '${period.year}-${period.month}';
	}
}
