import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../appointments/appointment_detail_screen.dart';
import 'home_screen.dart';

class HomeTabNavigator extends StatelessWidget {
	const HomeTabNavigator({super.key});

	@override
	Widget build(BuildContext context) {
		return Navigator(
			onGenerateRoute: (settings) {
				if (settings.name == AppointmentDetailScreen.routeName) {
					return MaterialPageRoute(
						settings: settings,
						builder: (context) => AppointmentDetailScreen(
							appointment: settings.arguments! as AppointmentRecord,
						),
					);
				}

				return MaterialPageRoute(
					settings: settings,
					builder: (context) => const HomeScreen(),
				);
			},
		);
	}
}
