import 'package:flutter/material.dart';

import '../models/onboarding_page.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class OnboardingPagesData {
	OnboardingPagesData._();

	static const pages = <OnboardingPage>[
		OnboardingPage(
			imageAsset: AppAssets.onboarding1,
		),
		OnboardingPage(
			title: 'Мастера защищают друг друга',
			description:
				'Делитесь опытом в закрытом сообществе — помогайте коллегам '
				'избегать рискованных клиентов и конфликтных ситуаций.',
			icon: Icons.groups_outlined,
			accentColor: AppColors.secondary,
		),
		OnboardingPage(
			title: 'Всё под контролем',
			description:
				'Записи на день, история проверок и профиль с тарифами — '
				'все инструменты мастера в одном приложении.',
			icon: Icons.dashboard_outlined,
			accentColor: AppColors.primary,
		),
	];
}
