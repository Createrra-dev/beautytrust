import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/home/app_bottom_navigation.dart';
import 'home_screen.dart';

class MainShellScreen extends StatefulWidget {
	const MainShellScreen({super.key});

	@override
	State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
	var _currentTab = AppTab.profile;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: BrandBackground(
				child: _buildBody(),
			),
			bottomNavigationBar: AppBottomNavigation(
				currentTab: _currentTab,
				onTabSelected: (tab) => setState(() => _currentTab = tab),
			),
		);
	}

	Widget _buildBody() {
		return switch (_currentTab) {
			AppTab.check => const _PlaceholderTab(title: 'Проверка'),
			AppTab.history => const _PlaceholderTab(title: 'История'),
			AppTab.community => const _PlaceholderTab(title: 'Сообщество'),
			AppTab.profile => const HomeScreen(),
		};
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
