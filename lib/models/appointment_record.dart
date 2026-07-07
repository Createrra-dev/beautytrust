import 'package:flutter/material.dart';

enum AppointmentRiskLevel {
	low,
	medium,
	high,
}

enum AppointmentLastChecked {
	today,
	oneDayAgo,
	threeDaysAgo,
}

class AppointmentRecord {
	const AppointmentRecord({
		required this.id,
		required this.clientName,
		required this.serviceName,
		required this.timeLabel,
		required this.dateLabel,
		required this.servicePrice,
		required this.clientRating,
		required this.riskLevel,
		required this.lastChecked,
	});

	final String id;
	final String clientName;
	final String serviceName;
	final String timeLabel;
	final String dateLabel;
	final int servicePrice;
	final double clientRating;
	final AppointmentRiskLevel riskLevel;
	final AppointmentLastChecked lastChecked;

	String get riskLabel {
		return switch (riskLevel) {
			AppointmentRiskLevel.low => 'Низкий риск',
			AppointmentRiskLevel.medium => 'Средний риск',
			AppointmentRiskLevel.high => 'Высокий риск',
		};
	}

	String get lastCheckedLabel {
		return switch (lastChecked) {
			AppointmentLastChecked.today => 'Сегодня',
			AppointmentLastChecked.oneDayAgo => '1 день назад',
			AppointmentLastChecked.threeDaysAgo => '3 дня назад',
		};
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
