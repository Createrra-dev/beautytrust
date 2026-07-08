import 'package:flutter/material.dart';

import '../../models/master_profile.dart';
import '../../models/tariff_payment_summary.dart';
import '../../models/tariff_plan.dart';
import 'edit_profile_screen.dart';
import 'master_profile_screen.dart';
import 'master_services_screen.dart';
import '../support/create_support_ticket_screen.dart';
import '../support/support_chat_screen.dart';
import '../support/support_tickets_screen.dart';
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
					case EditProfileScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => EditProfileScreen(
								profile: settings.arguments! as MasterProfile,
							),
						);
					case MasterServicesScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const MasterServicesScreen(),
						);
					case TariffsScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const TariffsScreen(),
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
					case SupportTicketsScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const SupportTicketsScreen(),
						);
					case CreateSupportTicketScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const CreateSupportTicketScreen(),
						);
					case SupportChatScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => SupportChatScreen(
								ticketId: settings.arguments! as String,
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
