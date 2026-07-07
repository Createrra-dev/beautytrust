import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

import '../../theme/app_theme.dart';

class AppBottomNavigation extends StatelessWidget {
	const AppBottomNavigation({
		super.key,
		required this.controller,
		required this.onTabSelected,
	});

	final MotionTabBarController controller;
	final ValueChanged<int> onTabSelected;

	static const tabLabels = [
		'Профиль',
		'Проверка',
		'История',
		'Сообщество',
	];

	@override
	Widget build(BuildContext context) {
		return MotionTabBar(
			controller: controller,
			initialSelectedTab: tabLabels.first,
			labels: tabLabels,
			icons: const [
				Icons.person_outline_rounded,
				Icons.verified_user_outlined,
				Icons.schedule_outlined,
				Icons.people_outline_rounded,
			],
			tabBarColor: AppColors.surface,
			tabBarHeight: 62,
			tabSize: 52,
			tabIconColor: AppColors.textMuted,
			tabIconSize: 24,
			tabIconSelectedSize: 22,
			tabSelectedColor: AppColors.primary,
			tabIconSelectedColor: AppColors.textPrimary,
			textStyle: const TextStyle(
				color: AppColors.textPrimary,
				fontSize: 11,
				fontWeight: FontWeight.w600,
			),
			useSafeArea: true,
			onTabItemSelected: onTabSelected,
		);
	}
}
