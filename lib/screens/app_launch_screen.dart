import 'package:flutter/material.dart';

import '../screens/auth/phone_login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../services/onboarding_storage.dart';
import '../theme/app_theme.dart';

class AppLaunchScreen extends StatefulWidget {
	const AppLaunchScreen({super.key});

	@override
	State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
	@override
	void initState() {
		super.initState();
		_resolveInitialScreen();
	}

	Future<void> _resolveInitialScreen() async {
		final onboardingCompleted = await OnboardingStorage.isCompleted();
		if (!mounted) {
			return;
		}

		final nextScreen = onboardingCompleted
			? const PhoneLoginScreen()
			: const OnboardingScreen();

		Navigator.of(context).pushReplacement(
			MaterialPageRoute(builder: (context) => nextScreen),
		);
	}

	@override
	Widget build(BuildContext context) {
		return const Scaffold(
			backgroundColor: AppColors.background,
			body: Center(
				child: CircularProgressIndicator(),
			),
		);
	}
}
