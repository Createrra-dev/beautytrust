import '../models/tariff_plan.dart';
import '../services/api/app_api_repository.dart';
import '../services/api/beauty_trust_api.dart';

class TariffPlansData {
	TariffPlansData._();

	static final AppApiRepository _api = AppApiRepository();
	static List<TariffPlan> _cache = [];

	static const List<TariffPlan> masterPlansFallback = [
		TariffPlan(
			id: 'free',
			title: 'Бесплатно',
			monthlyPrice: 0,
			trialLabel: '1 месяц бесплатно',
			features: [
				'Проверка клиентов по номеру',
				'Отзывы мастеров',
				'Базовая аналитика',
				'Уведомления о рисках',
			],
			cardButtonLabel: 'Попробовать бесплатно',
			audience: TariffAudience.masters,
		),
		TariffPlan(
			id: 'master',
			title: 'Мастер',
			monthlyPrice: 799,
			trialLabel: '1 месяц бесплатно',
			features: [
				'Проверка клиентов по номеру',
				'Отзывы мастеров',
				'Базовая аналитика',
				'Уведомления о рисках',
				'Приоритетная поддержка',
				'Экспорт данных',
			],
			cardButtonLabel: 'Выбрать тариф',
			audience: TariffAudience.masters,
			isPopular: true,
		),
	];

	static const List<TariffPlan> studioPlansFallback = [
		TariffPlan(
			id: 'studio',
			title: 'Студия',
			monthlyPrice: 2490,
			trialLabel: '14 дней бесплатно',
			features: [
				'До 5 мастеров в аккаунте',
				'Проверка клиентов по номеру',
				'Общая аналитика студии',
				'Уведомления о рисках',
			],
			cardButtonLabel: 'Выбрать тариф',
			audience: TariffAudience.studios,
		),
		TariffPlan(
			id: 'studio_pro',
			title: 'Студия Pro',
			monthlyPrice: 4990,
			trialLabel: '14 дней бесплатно',
			features: [
				'Неограниченно мастеров',
				'Проверка клиентов по номеру',
				'Расширенная аналитика',
				'Приоритетная поддержка',
				'Экспорт данных',
			],
			cardButtonLabel: 'Выбрать тариф',
			audience: TariffAudience.studios,
			isPopular: true,
		),
	];

	static List<TariffPlan> get masterPlans {
		final plans = _cache.where((plan) => plan.audience == TariffAudience.masters).toList();
		return plans.isEmpty ? masterPlansFallback : plans;
	}

	static List<TariffPlan> get studioPlans {
		final plans = _cache.where((plan) => plan.audience == TariffAudience.studios).toList();
		return plans.isEmpty ? studioPlansFallback : plans;
	}

	static Future<List<TariffPlan>> load({TariffAudience? audience}) async {
		try {
			_cache = await _api.fetchTariffs(
				audience: audience == null
					? null
					: (audience == TariffAudience.studios ? 'studios' : 'masters'),
			);
			if (audience == null && _cache.isEmpty) {
				_cache = await _api.fetchTariffs();
			}
		} on ApiException {
			if (_cache.isEmpty) {
				_cache = [...masterPlansFallback, ...studioPlansFallback];
			}
		}
		return plansFor(audience ?? TariffAudience.masters);
	}

	static List<TariffPlan> plansFor(TariffAudience audience) {
		return switch (audience) {
			TariffAudience.masters => masterPlans,
			TariffAudience.studios => studioPlans,
		};
	}

	static TariffPlan? planById(String id) {
		for (final plan in [...masterPlans, ...studioPlans]) {
			if (plan.id == id) {
				return plan;
			}
		}
		return null;
	}
}
