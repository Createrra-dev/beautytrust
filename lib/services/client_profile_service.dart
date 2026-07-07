import '../models/appointment_record.dart';
import '../models/client_profile.dart';

class ClientProfileService {
	ClientProfileService._();

	static ClientProfile profileFor(AppointmentRecord appointment) {
		return _profilesById[appointment.id] ?? _profileFromAppointment(appointment);
	}

	static ClientProfile _profileFromAppointment(AppointmentRecord appointment) {
		final ratingLabel = _ratingLabel(appointment.clientRating);

		return ClientProfile(
			phone: '+7 (999) 000-00-00',
			ratingLabel: ratingLabel,
			reviewsAverage: appointment.clientRating,
			reviewsCount: 12,
			noShowsCount: appointment.riskLevel == AppointmentRiskLevel.high ? 2 : 0,
			scandalsCount: 0,
			reviews: const [
				MasterReview(
					masterName: 'Анна П.',
					rating: 4,
					text: 'Клиентка пришла вовремя, всё отлично',
					tag: 'Молчаливая',
				),
			],
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
		'3': const ClientProfile(
			phone: '+7 (999) 123-45-67',
			ratingLabel: 'Хороший',
			reviewsAverage: 4.2,
			reviewsCount: 23,
			noShowsCount: 1,
			scandalsCount: 0,
			reviews: [
				MasterReview(
					masterName: 'Анна П.',
					rating: 4,
					text: 'Клиентка пришла вовремя, всё отлично',
					tag: 'Молчаливая',
				),
				MasterReview(
					masterName: 'Мария К.',
					rating: 3,
					text: 'Перенесла запись 2 раза, без предупреждения, молчала накануне',
					tag: 'Молчаливая',
				),
			],
			reliabilityTitle: 'Клиент в целом надёжный',
			reliabilitySubtitle: 'Рекомендуем к записи',
		),
		'1': const ClientProfile(
			phone: '+7 (999) 234-56-78',
			ratingLabel: 'Отличный',
			reviewsAverage: 4.9,
			reviewsCount: 31,
			noShowsCount: 0,
			scandalsCount: 0,
			reviews: [
				MasterReview(
					masterName: 'Ольга С.',
					rating: 5,
					text: 'Пунктуальная, приятная в общении',
					tag: 'Пунктуальная',
				),
				MasterReview(
					masterName: 'Ирина Л.',
					rating: 5,
					text: 'Приходит заранее, всегда благодарит',
					tag: 'Вежливая',
				),
			],
			reliabilityTitle: 'Клиент в целом надёжный',
			reliabilitySubtitle: 'Рекомендуем к записи',
		),
		'9': const ClientProfile(
			phone: '+7 (999) 876-54-32',
			ratingLabel: 'Ненадёжный',
			reviewsAverage: 1.8,
			reviewsCount: 9,
			noShowsCount: 4,
			scandalsCount: 1,
			reviews: [
				MasterReview(
					masterName: 'Елена В.',
					rating: 2,
					text: 'Не пришла на запись, телефон не отвечала',
					tag: 'Неявка',
				),
				MasterReview(
					masterName: 'Ксения Р.',
					rating: 1,
					text: 'Опоздала на 40 минут, извинений не было',
					tag: 'Конфликтная',
				),
			],
			reliabilityTitle: 'Клиент ненадёжный',
			reliabilitySubtitle: 'Рекомендуем отказать в записи',
		),
	};
}
