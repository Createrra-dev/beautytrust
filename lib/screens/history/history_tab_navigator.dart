import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../appointments/appointment_detail_screen.dart';
import 'check_history_screen.dart';

class HistoryTabNavigator extends StatelessWidget {
	const HistoryTabNavigator({super.key});

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
					builder: (context) => const CheckHistoryScreen(),
				);
			},
		);
	}
}
