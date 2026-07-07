import 'package:flutter/material.dart';

import '../../models/tariff_payment_summary.dart';
import '../../models/tariff_plan.dart';
import 'master_profile_screen.dart';
import 'tariff_detail_screen.dart';
import 'tariff_payment_screen.dart';
import 'tariff_success_screen.dart';
import 'tariffs_screen.dart';

class ProfileTabNavigator extends StatelessWidget {
	const ProfileTabNavigator({super.key});

	@override
	Widget build(BuildContext context) {
		return Navigator(
			onGenerateRoute: (settings) {
				switch (settings.name) {
					case TariffsScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const TariffsScreen(),
						);
					case TariffDetailScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => TariffDetailScreen(
								plan: settings.arguments! as TariffPlan,
							),
						);
					case TariffPaymentScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => TariffPaymentScreen(
								plan: settings.arguments! as TariffPlan,
							),
						);
					case TariffSuccessScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => TariffSuccessScreen(
								summary: settings.arguments! as TariffPaymentSummary,
							),
						);
					default:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const MasterProfileScreen(),
						);
				}
			},
		);
	}
}
