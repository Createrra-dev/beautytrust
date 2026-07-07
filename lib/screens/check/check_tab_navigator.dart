import 'package:flutter/material.dart';

import 'client_check_screen.dart';
import 'how_it_works_screen.dart';

class CheckTabNavigator extends StatelessWidget {
	const CheckTabNavigator({super.key});

	@override
	Widget build(BuildContext context) {
		return Navigator(
			onGenerateRoute: (settings) {
				if (settings.name == HowItWorksScreen.routeName) {
					return MaterialPageRoute(
						settings: settings,
						builder: (context) => const HowItWorksScreen(),
					);
				}

				return MaterialPageRoute(
					settings: settings,
					builder: (context) => const ClientCheckScreen(),
				);
			},
		);
	}
}
