import 'package:flutter/material.dart';

import 'master_profile_screen.dart';

class ProfileTabNavigator extends StatelessWidget {
	const ProfileTabNavigator({super.key});

	@override
	Widget build(BuildContext context) {
		return Navigator(
			onGenerateRoute: (settings) {
				return MaterialPageRoute(
					settings: settings,
					builder: (context) => const MasterProfileScreen(),
				);
			},
		);
	}
}
