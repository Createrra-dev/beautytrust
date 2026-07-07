import 'package:flutter/material.dart';

import '../models/onboarding_page.dart';
import '../theme/app_theme.dart';

class OnboardingPagesData {
	OnboardingPagesData._();

	static const pages = <OnboardingPage>[
		OnboardingPage(
			stepNumber: 1,
			titleParts: [
				OnboardingTextPart(text: 'Проверяй клиентов\n'),
				OnboardingTextPart(
					text: 'до записи',
					color: AppColors.secondary,
				),
			],
			subtitle: 'Узнай всю важную информацию о клиенте за пару секунд',
			features: [
				OnboardingFeature(
					title: 'Быстрый поиск',
					description:
						'Найди клиента по номеру телефона и узнай его рейтинг',
					icon: Icons.person_search_outlined,
				),
				OnboardingFeature(
					title: 'Оцени риски',
					description:
						'Сервис покажет уровень риска и историю проблем',
					icon: Icons.verified_user_outlined,
				),
				OnboardingFeature(
					title: 'Прими решение',
					description:
						'Выбирай с кем работать, а с кем лучше отказаться',
					icon: Icons.trending_up_rounded,
				),
				OnboardingFeature(
					title: 'Меньше неявок и потерь',
					description: 'Экономь время и защищай свой доход',
					icon: Icons.event_busy_outlined,
				),
			],
			footerNote: OnboardingFooterNote(
				leading: 'Проверка клиента занимает 2 секунды, а экономит тебе ',
				accent: 'часы и деньги',
				trailing: '',
				caption: 'BeautyTrust — работай уверенно с каждым клиентом',
				icon: Icons.mic_none_rounded,
			),
		),
		OnboardingPage(
			stepNumber: 2,
			titleParts: [
				OnboardingTextPart(text: 'Работай '),
				OnboardingTextPart(
					text: 'спокойно ',
					color: Color(0xFF5EEAD4),
				),
				OnboardingTextPart(
					text: 'и уверенно',
					useBrandGradient: true,
				),
			],
			subtitle:
				'BeautyTrust проверяет клиента до записи и помогает избежать риска',
			features: [
				OnboardingFeature(
					title: 'Меньше неявок',
					description:
						'Видишь риск клиента заранее и экономишь время',
					icon: Icons.event_available_outlined,
				),
				OnboardingFeature(
					title: 'Защита репутации',
					description:
						'Избегай конфликтов, спорных клиентов и негатива',
					icon: Icons.shield_outlined,
				),
				OnboardingFeature(
					title: 'Больше дохода',
					description:
						'Берёшь надёжных клиентов и заполняешь окно без потерь',
					icon: Icons.bar_chart_rounded,
				),
				OnboardingFeature(
					title: 'Быстрая проверка',
					description: 'Результат за 2 секунды по номеру телефона',
					icon: Icons.bolt_outlined,
				),
			],
		),
		OnboardingPage(
			stepNumber: 3,
			titleParts: [
				OnboardingTextPart(text: 'Больше довольных\n'),
				OnboardingTextPart(
					text: 'клиентов и дохода',
					useBrandGradient: true,
				),
			],
			subtitle: 'Качество сервиса начинается с правильного выбора клиентов',
			features: [
				OnboardingFeature(
					title: 'Довольные клиенты',
					description:
						'Работай с теми, кто ценит твоё время и труд',
					icon: Icons.star_outline_rounded,
				),
				OnboardingFeature(
					title: 'Больше записей',
					description:
						'Надёжные клиенты возвращаются и рекомендуют тебя',
					icon: Icons.trending_up_rounded,
				),
				OnboardingFeature(
					title: 'Выше доход',
					description: 'Меньше отмен — больше стабильного заработка',
					icon: Icons.account_balance_wallet_outlined,
				),
			],
			highlight: OnboardingHighlight(
				title: 'Рост без лишних рисков',
				description: 'Выбирай клиентов — увеличивай прибыль',
				icon: Icons.emoji_events_outlined,
			),
			testimonial: OnboardingTestimonial(
				authorName: 'Анна',
				role: 'Мастер-бровист',
				quote:
					'С BeautyTrust я перестала терять время на ненадёжных клиентов '
					'и начала зарабатывать больше. Теперь у меня только те, '
					'кто уважает мой труд и ценит моё время',
			),
		),
	];
}
