import '../data/demo_master_reviews.dart';
import '../services/api/app_api_repository.dart';
import '../models/appointment_record.dart';
import '../models/client_check_result.dart';
import '../models/client_profile.dart';
import '../utils/phone_formatter.dart';

class ClientProfileService {
	ClientProfileService._();

	static final AppApiRepository _api = AppApiRepository();
	static final Map<String, ClientProfile> _profileCache = {};

	static Future<ClientCheckResult?> lookupByPhone(String rawPhone) async {
		return _api.checkClient(rawPhone);
	}

	static ClientProfile profileFor(AppointmentRecord appointment) {
		final cached = _profileCache[appointment.clientPhoneDigits];
		if (cached != null) {
			return cached;
		}

		return _profileFromAppointment(appointment);
	}

	static void cacheProfile(String phoneDigits, ClientProfile profile) {
		_profileCache[phoneDigits] = profile;
	}

	static ClientProfile _profileFromAppointment(AppointmentRecord appointment) {
		final ratingLabel = _ratingLabel(appointment.clientRating);
		final reviews = DemoMasterReviews.ekaterina;
		final phone = appointment.clientPhoneDigits.length == 10
			? formatPhoneDisplay(appointment.clientPhoneDigits)
			: '+7 (999) 000-00-00';

		return ClientProfile(
			phone: phone,
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
}
