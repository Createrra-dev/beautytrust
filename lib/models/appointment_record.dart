import 'package:flutter/material.dart';

import '../utils/phone_formatter.dart';
import 'visit_result.dart';

enum AppointmentRiskLevel {
	low,
	medium,
	high,
}

enum AppointmentStatus {
	scheduled,
	completed,
	noShow,
	cancelled,
}

class AppointmentRecord {
	AppointmentRecord({
		required this.id,
		required this.clientName,
		required this.clientPhoneDigits,
		required this.serviceName,
		required this.serviceDurationLabel,
		required this.scheduledAt,
		required this.servicePrice,
		required this.clientRating,
		required this.riskLevel,
		required this.daysSinceVerified,
		this.status = AppointmentStatus.scheduled,
		this.visitResult,
		this.source = 'manual',
		this.yclientsStaffName,
		this.yclientsStaffAvatarUrl,
	});

	final String id;
	final String clientName;
	final String clientPhoneDigits;
	final String serviceName;
	final String serviceDurationLabel;
	final DateTime scheduledAt;
	final int servicePrice;
	final double clientRating;
	final AppointmentRiskLevel riskLevel;
	final int daysSinceVerified;
	final AppointmentStatus status;
	final VisitResult? visitResult;
	final String source;
	final String? yclientsStaffName;
	final String? yclientsStaffAvatarUrl;

	bool get isFromYClients => source == 'yclients';

	String get dateLabel => formatAppointmentDateLabel(scheduledAt);

	String get timeLabel => formatAppointmentTimeLabel(scheduledAt);

	String get phoneDisplay {
		if (clientPhoneDigits.length != 10) {
			return clientPhoneDigits;
		}

		return formatPhoneDisplay(clientPhoneDigits);
	}

	AppointmentRecord copyWith({
		String? clientName,
		String? clientPhoneDigits,
		String? serviceName,
		String? serviceDurationLabel,
		DateTime? scheduledAt,
		int? servicePrice,
		double? clientRating,
		AppointmentRiskLevel? riskLevel,
		int? daysSinceVerified,
		AppointmentStatus? status,
		VisitResult? visitResult,
		String? source,
		String? yclientsStaffName,
		String? yclientsStaffAvatarUrl,
	}) {
		return AppointmentRecord(
			id: id,
			clientName: clientName ?? this.clientName,
			clientPhoneDigits: clientPhoneDigits ?? this.clientPhoneDigits,
			serviceName: serviceName ?? this.serviceName,
			serviceDurationLabel: serviceDurationLabel ?? this.serviceDurationLabel,
			scheduledAt: scheduledAt ?? this.scheduledAt,
			servicePrice: servicePrice ?? this.servicePrice,
			clientRating: clientRating ?? this.clientRating,
			riskLevel: riskLevel ?? this.riskLevel,
			daysSinceVerified: daysSinceVerified ?? this.daysSinceVerified,
			status: status ?? this.status,
			visitResult: visitResult ?? this.visitResult,
			source: source ?? this.source,
			yclientsStaffName: yclientsStaffName ?? this.yclientsStaffName,
			yclientsStaffAvatarUrl: yclientsStaffAvatarUrl ?? this.yclientsStaffAvatarUrl,
		);
	}

	String get statusLabel {
		return switch (status) {
			AppointmentStatus.scheduled => 'Запланирована',
			AppointmentStatus.completed => 'Завершена',
			AppointmentStatus.noShow => 'Неявка',
			AppointmentStatus.cancelled => 'Отменена',
		};
	}

	String get riskLabel {
		return switch (riskLevel) {
			AppointmentRiskLevel.low => 'Низкий риск',
			AppointmentRiskLevel.medium => 'Средний риск',
			AppointmentRiskLevel.high => 'Высокий риск',
		};
	}

	bool isActiveAt(DateTime referenceNow) {
		return !scheduledAt.isBefore(referenceNow);
	}

	bool isPastAt(DateTime referenceNow) {
		return scheduledAt.isBefore(referenceNow);
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
