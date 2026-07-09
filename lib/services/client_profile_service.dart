import '../models/appointment_record.dart';
import '../models/client_check_result.dart';
import '../models/client_profile.dart';
import '../services/api/app_api_repository.dart';
import '../utils/phone_formatter.dart';
import 'api/beauty_trust_api.dart';

class ClientProfileService {
	ClientProfileService._();

	static final AppApiRepository _api = AppApiRepository();
	static final Map<String, ClientProfile> _profileCache = {};

	static Future<ClientCheckResult?> lookupByPhone(String rawPhone) async {
		final result = await _api.checkClient(rawPhone);
		if (result != null) {
			cacheProfile(_phoneDigitsFromDisplay(result.profile.phone), result.profile);
		}
		return result;
	}

	static Future<ClientProfile?> fetchProfileForPhone(String phoneDigits) async {
		final cached = _profileCache[phoneDigits];
		if (cached != null) {
			return cached;
		}

		try {
			final profile = await _api.fetchClientProfile(phoneDigits);
			_profileCache[phoneDigits] = profile;
			return profile;
		} on ApiException catch (error) {
			if (error.statusCode == 404) {
				return null;
			}
			rethrow;
		}
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

	static void invalidateCache(String phoneDigits) {
		_profileCache.remove(phoneDigits);
	}

	static ClientProfile _profileFromAppointment(AppointmentRecord appointment) {
		final ratingLabel = _ratingLabel(appointment.clientRating);
		final phone = appointment.clientPhoneDigits.length == 10
			? formatPhoneDisplay(appointment.clientPhoneDigits)
			: appointment.clientPhoneDigits;

		return ClientProfile(
			phone: phone,
			ratingLabel: ratingLabel,
			reviewsAverage: appointment.clientRating,
			reviewsCount: 0,
			noShowsCount: appointment.riskLevel == AppointmentRiskLevel.high ? 2 : 0,
			scandalsCount: appointment.riskLevel == AppointmentRiskLevel.high ? 1 : 0,
			reviews: const [],
			reliabilityTitle: _reliabilityTitle(appointment.clientRating),
			reliabilitySubtitle: _reliabilitySubtitle(appointment.clientRating),
		);
	}

	static String _phoneDigitsFromDisplay(String phone) {
		final digits = phone.replaceAll(RegExp(r'\D'), '');
		if (digits.length == 11 && digits.startsWith('7')) {
			return digits.substring(1);
		}
		return digits;
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
