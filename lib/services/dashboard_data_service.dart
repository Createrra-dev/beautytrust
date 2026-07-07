import '../models/appointment_record.dart';
import '../models/dashboard_period.dart';
import '../models/dashboard_stats.dart';

class DashboardDataService {
	DashboardDataService._();

	static final List<DashboardPeriod> availablePeriods = [
		const DashboardPeriod(year: 2026, month: 7),
		const DashboardPeriod(year: 2026, month: 6),
		const DashboardPeriod(year: 2026, month: 5),
		const DashboardPeriod(year: 2026, month: 4),
		const DashboardPeriod(year: 2026, month: 3),
		const DashboardPeriod(year: 2026, month: 2),
		const DashboardPeriod(year: 2026, month: 1),
		const DashboardPeriod(year: 2025, month: 12),
		const DashboardPeriod(year: 2025, month: 11),
		const DashboardPeriod(year: 2025, month: 10),
		const DashboardPeriod(year: 2024, month: 3),
		const DashboardPeriod(year: 2024, month: 2),
		const DashboardPeriod(year: 2024, month: 1),
	];

	static DashboardPeriod get defaultPeriod => availablePeriods.first;

	static DashboardStats statsFor(DashboardPeriod period) {
		final data = _statsByKey[_periodKey(period)];

		if (data != null) {
			return data;
		}

		return _generatedStats(period);
	}

	static List<AppointmentRecord> currentAppointments() {
		return const [
			AppointmentRecord(
				clientName: 'Анна Петрова',
				serviceName: 'Маникюр',
				timeLabel: '14:00',
				dateLabel: 'Сегодня',
				status: AppointmentStatus.confirmed,
			),
			AppointmentRecord(
				clientName: 'Мария Иванова',
				serviceName: 'Стрижка и укладка',
				timeLabel: '16:30',
				dateLabel: 'Сегодня',
				status: AppointmentStatus.pendingVerification,
			),
			AppointmentRecord(
				clientName: 'Екатерина Смирнова',
				serviceName: 'Окрашивание',
				timeLabel: '11:00',
				dateLabel: 'Завтра',
				status: AppointmentStatus.atRisk,
			),
		];
	}

	static String _periodKey(DashboardPeriod period) {
		return '${period.year}-${period.month}';
	}

	static DashboardStats _generatedStats(DashboardPeriod period) {
		final seed = period.year * 100 + period.month;
		final income = 90000 + (seed % 17) * 4500;
		final noShows = 6 + seed % 9;
		final checks = 180 + seed % 90;
		final trendPercent = 8 + seed % 25;

		return DashboardStats(
			periodLabel: period.label,
			protectedIncome: income,
			incomeTrendLabel: '+$trendPercent% к ${period.previousMonthLabel.toLowerCase()}',
			incomeTrendPositive: true,
			sparklineValues: _sparklineForSeed(seed),
			preventedNoShows: noShows,
			noShowsTrendLabel: '-${2 + seed % 4} к ${period.previousMonthLabel.toLowerCase()}',
			completedChecks: checks,
			checksTrendLabel: '+${10 + seed % 20} к ${period.previousMonthLabel.toLowerCase()}',
		);
	}

	static List<double> _sparklineForSeed(int seed) {
		final values = <double>[];
		var value = 0.3 + (seed % 5) * 0.04;

		for (var index = 0; index < 12; index++) {
			value += ((seed + index * 7) % 5 - 2) * 0.03;
			value = value.clamp(0.2, 1.0);
			values.add(value);
		}

		values[values.length - 1] = 1.0;
		return values;
	}

	static final Map<String, DashboardStats> _statsByKey = {
		'2024-3': const DashboardStats(
			periodLabel: 'Март 2024',
			protectedIncome: 156000,
			incomeTrendLabel: '+23% к февралю',
			incomeTrendPositive: true,
			sparklineValues: [0.35, 0.42, 0.38, 0.55, 0.48, 0.62, 0.58, 0.72, 0.68, 0.85, 0.78, 1.0],
			preventedNoShows: 12,
			noShowsTrendLabel: '-3 к февралю',
			completedChecks: 247,
			checksTrendLabel: '+31 к февралю',
		),
		'2026-7': const DashboardStats(
			periodLabel: 'Июль 2026',
			protectedIncome: 182000,
			incomeTrendLabel: '+18% к июню',
			incomeTrendPositive: true,
			sparklineValues: [0.4, 0.45, 0.5, 0.48, 0.58, 0.62, 0.7, 0.68, 0.8, 0.86, 0.92, 1.0],
			preventedNoShows: 15,
			noShowsTrendLabel: '-2 к июню',
			completedChecks: 268,
			checksTrendLabel: '+24 к июню',
		),
	};
}
