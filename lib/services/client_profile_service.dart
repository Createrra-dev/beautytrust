import '../data/demo_master_reviews.dart';
import '../models/appointment_record.dart';
import '../models/client_check_result.dart';
import '../models/client_profile.dart';
import '../utils/phone_formatter.dart';

class ClientProfileService {
	ClientProfileService._();

	static ClientProfile profileFor(AppointmentRecord appointment) {
		return _profilesById[appointment.id] ?? _profileFromAppointment(appointment);
	}

	static ClientCheckResult? lookupByPhone(String rawPhone) {
		final digits = extractPhoneDigits(rawPhone);
		if (digits.length != 10) {
			return null;
		}

		return _checksByPhoneDigits[digits];
	}

	static ClientProfile _profileFromAppointment(AppointmentRecord appointment) {
		final ratingLabel = _ratingLabel(appointment.clientRating);
		final reviews = DemoMasterReviews.ekaterina;

		return ClientProfile(
			phone: '+7 (999) 000-00-00',
			ratingLabel: ratingLabel,
			reviewsAverage: appointment.clientRating,
			reviewsCount: reviews.length,
			noShowsCount: appointment.riskLevel == AppointmentRiskLevel.high ? 2 : 0,
			scandalsCount: appointment.riskLevel == AppointmentRiskLevel.high ? 1 : 0,
			reviews: reviews,
			reliabilityTitle: _reliabilityTitle(appointment.clientRating),
			reliabilitySubtitle: _reliabilitySubtitle(appointment.clientRating),
		);
	}

	static String _ratingLabel(double rating) {
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

	static String _reliabilityTitle(double rating) {
		if (rating >= 4) {
			return 'Клиент в целом надёжный';
		}

		if (rating >= 3) {
			return 'Клиент требует внимания';
		}

		return 'Клиент ненадёжный';
	}

	static String _reliabilitySubtitle(double rating) {
		if (rating >= 4) {
			return 'Рекомендуем к записи';
		}

		if (rating >= 3) {
			return 'Рекомендуем предоплату';
		}

		return 'Рекомендуем отказать в записи';
	}

	static final Map<String, ClientProfile> _profilesById = {
		'3': ClientProfile(
			phone: '+7 (999) 123-45-67',
			ratingLabel: 'Хороший',
			reviewsAverage: 4.2,
			reviewsCount: DemoMasterReviews.ekaterina.length,
			noShowsCount: 1,
			scandalsCount: 0,
			reviews: DemoMasterReviews.ekaterina,
			reliabilityTitle: 'Клиент в целом надёжный',
			reliabilitySubtitle: 'Рекомендуем к записи',
		),
		'1': ClientProfile(
			phone: '+7 (999) 234-56-78',
			ratingLabel: 'Отличный',
			reviewsAverage: 4.9,
			reviewsCount: DemoMasterReviews.defaultSet.length,
			noShowsCount: 0,
			scandalsCount: 0,
			reviews: DemoMasterReviews.defaultSet,
			reliabilityTitle: 'Клиент в целом надёжный',
			reliabilitySubtitle: 'Рекомендуем к записи',
		),
		'9': ClientProfile(
			phone: '+7 (999) 876-54-32',
			ratingLabel: 'Ненадёжный',
			reviewsAverage: 1.8,
			reviewsCount: DemoMasterReviews.ekaterina.length,
			noShowsCount: 4,
			scandalsCount: 1,
			reviews: DemoMasterReviews.ekaterina,
			reliabilityTitle: 'Клиент ненадёжный',
			reliabilitySubtitle: 'Рекомендуем отказать в записи',
		),
	};

	static ClientProfile _buildProfile({
		required String phone,
		required double rating,
		required int noShowsCount,
		required int scandalsCount,
		required List<MasterReview> reviews,
	}) {
		return ClientProfile(
			phone: phone,
			ratingLabel: _ratingLabel(rating),
			reviewsAverage: rating,
			reviewsCount: reviews.length,
			noShowsCount: noShowsCount,
			scandalsCount: scandalsCount,
			reviews: reviews,
			reliabilityTitle: _reliabilityTitle(rating),
			reliabilitySubtitle: _reliabilitySubtitle(rating),
		);
	}

	static final Map<String, ClientCheckResult> _checksByPhoneDigits = {
		'9991234567': ClientCheckResult(
			clientName: 'Екатерина Смирнова',
			profile: _profilesById['3']!,
		),
		'9992345678': ClientCheckResult(
			clientName: 'Анна Петрова',
			profile: _profilesById['1']!,
		),
		'9998765432': ClientCheckResult(
			clientName: 'Ирина Соколова',
			profile: _profilesById['9']!,
		),
		'9165551234': ClientCheckResult(
			clientName: 'Клиент',
			profile: _buildProfile(
				phone: '+7 (916) 555-12-34',
				rating: 3.1,
				noShowsCount: 2,
				scandalsCount: 0,
				reviews: DemoMasterReviews.defaultSet,
			),
		),
		'9031112233': ClientCheckResult(
			clientName: 'Клиент',
			profile: _buildProfile(
				phone: '+7 (903) 111-22-33',
				rating: 4.5,
				noShowsCount: 0,
				scandalsCount: 0,
				reviews: DemoMasterReviews.defaultSet,
			),
		),
		'9254445566': ClientCheckResult(
			clientName: 'Клиент',
			profile: _buildProfile(
				phone: '+7 (925) 444-55-66',
				rating: 3.8,
				noShowsCount: 1,
				scandalsCount: 0,
				reviews: DemoMasterReviews.ekaterina,
			),
		),
	};
}
