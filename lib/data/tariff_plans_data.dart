import '../models/tariff_plan.dart';

class TariffPlansData {
	TariffPlansData._();

	static const List<TariffPlan> masterPlans = [
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

	static const List<TariffPlan> studioPlans = [
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
