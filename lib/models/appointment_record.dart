import 'package:flutter/material.dart';

enum AppointmentRiskLevel {
	low,
	medium,
	high,
}

class AppointmentRecord {
	const AppointmentRecord({
		required this.id,
		required this.clientName,
		required this.serviceName,
		required this.serviceDurationLabel,
		required this.timeLabel,
		required this.dateLabel,
		required this.servicePrice,
		required this.clientRating,
		required this.riskLevel,
		required this.daysSinceVerified,
	});

	final String id;
	final String clientName;
	final String serviceName;
	final String serviceDurationLabel;
	final String timeLabel;
	final String dateLabel;
	final int servicePrice;
	final double clientRating;
	final AppointmentRiskLevel riskLevel;
	final int daysSinceVerified;

	String get riskLabel {
		return switch (riskLevel) {
			AppointmentRiskLevel.low => 'Низкий риск',
			AppointmentRiskLevel.medium => 'Средний риск',
			AppointmentRiskLevel.high => 'Высокий риск',
		};
	}

	String get verifiedLabel {
		if (daysSinceVerified <= 0) {
			return 'Проверен сегодня';
		}

		return 'Проверен $daysSinceVerified дн. назад';
	}

	String get verifiedSubtitle {
		if (daysSinceVerified <= 0) {
			return 'сегодня';
		}

		return '$daysSinceVerified дн. назад';
	}

	String get priceLineLabel {
		return '$serviceDurationLabel • ${formatServicePrice(servicePrice)}';
	}
}

Color appointmentRatingColor(double rating) {
	if (rating < 3) {
		return const Color(0xFFF87171);
	}

	if (rating < 4) {
		return const Color(0xFFFBBF24);
	}

	return const Color(0xFF34D399);
}

Color appointmentRiskColor(AppointmentRiskLevel riskLevel) {
	return switch (riskLevel) {
		AppointmentRiskLevel.low => const Color(0xFF34D399),
		AppointmentRiskLevel.medium => const Color(0xFFFBBF24),
		AppointmentRiskLevel.high => const Color(0xFFF87171),
	};
}

String formatAppointmentRating(double rating) {
	final clampedRating = rating.clamp(1.0, 5.0);
	return clampedRating.toStringAsFixed(1);
}

String appointmentRatingLabel(double rating) {
	if (rating >= 4.5) {
		return 'Отличный';
	}

	if (rating >= 4) {
		return 'Хороший';
	}

	if (rating >= 3) {
		return 'Средний';
	}

	return 'Ненадёжный';
}

String formatReviewMonthYear(DateTime date) {
	const monthLabels = [
		'янв',
		'фев',
		'мар',
		'апр',
		'май',
		'июн',
		'июл',
		'авг',
		'сен',
		'окт',
		'ноя',
		'дек',
	];

	return '${monthLabels[date.month - 1]} ${date.year}';
}

String formatServicePrice(int price) {
	final text = price.toString();
	final buffer = StringBuffer();

	for (var index = 0; index < text.length; index++) {
		final positionFromEnd = text.length - index;
		if (index > 0 && positionFromEnd % 3 == 0) {
			buffer.write(' ');
		}
		buffer.write(text[index]);
	}

	return '${buffer.toString()} ₽';
}

String formatAppointmentDateLabel(DateTime date, {DateTime? referenceNow}) {
	final now = referenceNow ?? DateTime.now();
	final today = DateTime(now.year, now.month, now.day);
	final target = DateTime(date.year, date.month, date.day);
	final tomorrow = today.add(const Duration(days: 1));

	if (target == today) {
		return 'Сегодня';
	}

	if (target == tomorrow) {
		return 'Завтра';
	}

	const monthLabels = [
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

	return '${date.day} ${monthLabels[date.month - 1]}';
}

String formatAppointmentTimeLabel(DateTime date) {
	return '${date.hour.toString().padLeft(2, '0')}:'
		'${date.minute.toString().padLeft(2, '0')}';
}

AppointmentRiskLevel appointmentRiskLevelForRating(double rating) {
	if (rating >= 4) {
		return AppointmentRiskLevel.low;
	}

	if (rating >= 3) {
		return AppointmentRiskLevel.medium;
	}

	return AppointmentRiskLevel.high;
}
