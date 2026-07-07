import '../models/check_history_record.dart';

class CheckHistoryDataService {
	CheckHistoryDataService._();

	static List<CheckHistoryRecord> allChecks({DateTime? referenceNow}) {
		final now = referenceNow ?? DateTime.now();
		final today = DateTime(now.year, now.month, now.day);

		return [
			CheckHistoryRecord(
				id: '1',
				phone: '+7 (999) 123-45-67',
				rating: 4.2,
				checkedAt: today.add(const Duration(hours: 14, minutes: 30)),
				appointmentId: '3',
			),
			CheckHistoryRecord(
				id: '2',
				phone: '+7 (999) 234-56-78',
				rating: 4.9,
				checkedAt: today.add(const Duration(hours: 10, minutes: 15)),
				appointmentId: '1',
			),
			CheckHistoryRecord(
				id: '3',
				phone: '+7 (916) 555-12-34',
				rating: 3.1,
				checkedAt: today
					.subtract(const Duration(days: 1))
					.add(const Duration(hours: 18, minutes: 45)),
			),
			CheckHistoryRecord(
				id: '4',
				phone: '+7 (999) 876-54-32',
				rating: 2.1,
				checkedAt: DateTime(now.year, 3, 12, 11, 20),
				appointmentId: '9',
			),
			CheckHistoryRecord(
				id: '5',
				phone: '+7 (903) 111-22-33',
				rating: 4.5,
				checkedAt: DateTime(now.year, 3, 10, 9),
			),
			CheckHistoryRecord(
				id: '6',
				phone: '+7 (925) 444-55-66',
				rating: 3.8,
				checkedAt: DateTime(now.year, 3, 8, 16, 30),
			),
			CheckHistoryRecord(
				id: '7',
				phone: '+7 (977) 333-44-55',
				rating: 4.6,
				checkedAt: DateTime(now.year, 2, 28, 13, 10),
			),
			CheckHistoryRecord(
				id: '8',
				phone: '+7 (915) 222-33-44',
				rating: 2.8,
				checkedAt: DateTime(now.year, 2, 20, 17, 45),
			),
		];
	}

	static List<CheckHistoryRecord> checksFor(
		CheckHistoryFilter filter, {
		DateTime? referenceNow,
	}) {
		final checks = allChecks(referenceNow: referenceNow);

		return switch (filter) {
			CheckHistoryFilter.all => checks,
			CheckHistoryFilter.reliable =>
				checks.where((check) => check.isReliable).toList(),
			CheckHistoryFilter.risky =>
				checks.where((check) => check.isRisky).toList(),
		};
	}
}
