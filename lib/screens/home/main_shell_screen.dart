import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

import '../../theme/app_theme.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/home/app_bottom_navigation.dart';
import 'home_tab_navigator.dart';

class MainShellScreen extends StatefulWidget {
	const MainShellScreen({super.key});

	@override
	State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
		with SingleTickerProviderStateMixin {
	late final MotionTabBarController _motionTabBarController;

	@override
	void initState() {
		super.initState();
		_motionTabBarController = MotionTabBarController(
			initialIndex: AppBottomNavigation.homeTabIndex,
			length: AppBottomNavigation.tabLabels.length,
			vsync: this,
		);
	}

	@override
	void dispose() {
		_motionTabBarController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: BrandBackground(
				child: TabBarView(
					physics: const NeverScrollableScrollPhysics(),
					controller: _motionTabBarController,
					children: const [
						_PlaceholderTab(title: 'Сообщество'),
						_PlaceholderTab(title: 'Профиль'),
						HomeTabNavigator(),
						_PlaceholderTab(title: 'Проверка'),
						_PlaceholderTab(title: 'История'),
					],
				),
			),
			bottomNavigationBar: AppBottomNavigation(
				controller: _motionTabBarController,
				onTabSelected: (index) {
					setState(() {
						_motionTabBarController.index = index;
					});
				},
			),
		);
	}
}

class _PlaceholderTab extends StatelessWidget {
	const _PlaceholderTab({required this.title});

	final String title;

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Center(
				child: Text(
					title,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 18,
						fontWeight: FontWeight.w500,
					),
				),
			),
		);
	}
}
