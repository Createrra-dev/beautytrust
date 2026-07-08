import 'appointment_record.dart';

enum CheckHistoryFilter {
	all,
	reliable,
	risky,
}

class CheckHistoryRecord {
	const CheckHistoryRecord({
		required this.id,
		required this.phone,
		required this.rating,
		required this.checkedAt,
		this.clientName,
		this.riskLevel,
		this.appointmentId,
	});

	final String id;
	final String phone;
	final double rating;
	final DateTime checkedAt;
	final String? clientName;
	final AppointmentRiskLevel? riskLevel;
	final String? appointmentId;

	String get ratingLabel => appointmentRatingLabel(rating);

	bool get isReliable => rating >= 4;

	bool get isRisky => rating < 3.5;
}

String formatCheckPerformedAt(DateTime checkedAt, {DateTime? referenceNow}) {
	final now = referenceNow ?? DateTime.now();
	final timeLabel =
		'${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}';

	if (_isSameDay(checkedAt, now)) {
		return 'Сегодня, $timeLabel';
	}

	final yesterday = DateTime(now.year, now.month, now.day - 1);
	if (_isSameDay(checkedAt, yesterday)) {
		return 'Вчера, $timeLabel';
	}

	return '${checkedAt.day} ${_monthGenitiveLabels[checkedAt.month - 1]}, $timeLabel';
}

bool _isSameDay(DateTime left, DateTime right) {
	return left.year == right.year
		&& left.month == right.month
		&& left.day == right.day;
}

const _monthGenitiveLabels = [
	'января',
	'февраля',
	'марта',
	'апреля',
	'мая',
	'июня',
	'июля',
	'августа',
	'сентября',
	'октября',
	'ноября',
	'декабря',
];
