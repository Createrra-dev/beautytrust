import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

import '../../navigation/main_shell_navigation.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/home/app_bottom_navigation.dart';
import '../community/community_tab_navigator.dart';
import '../check/check_tab_navigator.dart';
import '../history/history_tab_navigator.dart';
import '../profile/profile_tab_navigator.dart';
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
		MainShellNavigation.instance.register(_selectTab);
	}

	void _selectTab(int index) {
		setState(() {
			_motionTabBarController.index = index;
		});
	}

	@override
	void dispose() {
		MainShellNavigation.instance.unregister();
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
						CheckTabNavigator(),
						CommunityTabNavigator(),
						HomeTabNavigator(),
						HistoryTabNavigator(),
						ProfileTabNavigator(),
					],
				),
			),
			bottomNavigationBar: AppBottomNavigation(
				controller: _motionTabBarController,
				onTabSelected: _selectTab,
			),
		);
	}
}
