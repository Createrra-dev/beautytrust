import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

import '../../theme/app_theme.dart';
import '../app_logo.dart';
import 'beauty_motion_tab_bar.dart';

class AppBottomNavigation extends StatelessWidget {
	const AppBottomNavigation({
		super.key,
		required this.controller,
		required this.onTabSelected,
	});

	final MotionTabBarController controller;
	final ValueChanged<int> onTabSelected;

	static const tabLabels = [
		'Проверка',
		'Сообщество',
		'Home',
		'История',
		'Профиль',
	];

	static const homeTabIndex = 2;
	static const checkTabIndex = 0;

	static const _checkTabLogoSize = 26.0;
	static const _checkTabLogoSelectedSize = 24.0;

	@override
	Widget build(BuildContext context) {
		return DecoratedBox(
			decoration: const BoxDecoration(
				border: Border(
					top: BorderSide(color: AppColors.border),
				),
			),
			child: BeautyMotionTabBar(
				controller: controller,
				initialSelectedTab: tabLabels[homeTabIndex],
				labels: tabLabels,
				icons: const [
					Icons.verified_user_outlined,
					Icons.people_outline_rounded,
					Icons.home_outlined,
					Icons.schedule_outlined,
					Icons.person_outline_rounded,
				],
				iconWidgets: [
					_checkTabLogo(_checkTabLogoSize),
					null,
					null,
					null,
					null,
				],
				tabBarColor: AppColors.background,
				tabBarHeight: 62,
				tabSize: 48,
				tabIconColor: AppColors.textMuted,
				tabIconSize: 22,
				tabIconSelectedSize: _checkTabLogoSelectedSize,
				tabSelectedColor: AppColors.primary,
				tabIconSelectedColor: AppColors.textPrimary,
				textStyle: const TextStyle(
					color: AppColors.textPrimary,
					fontSize: 10,
					fontWeight: FontWeight.w600,
				),
				useSafeArea: true,
				onTabItemSelected: onTabSelected,
			),
		);
	}

	static Widget _checkTabLogo(double size) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(size * 0.22),
			child: Image.asset(
				AppAssets.logo,
				width: size,
				height: size,
				fit: BoxFit.cover,
			),
		);
	}
}
