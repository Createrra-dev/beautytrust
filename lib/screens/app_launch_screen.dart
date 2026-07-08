import 'package:flutter/material.dart';

import '../screens/auth/phone_login_screen.dart';
import '../screens/auth/pin_code_screen.dart';
import '../screens/home/main_shell_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../services/auth_session.dart';
import '../services/biometric_auth_service.dart';
import '../services/onboarding_storage.dart';
import '../theme/app_theme.dart';

class AppLaunchScreen extends StatefulWidget {
	const AppLaunchScreen({super.key});

	@override
	State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
	final _biometricAuthService = BiometricAuthService();

	@override
	void initState() {
		super.initState();
		_resolveInitialScreen();
	}

	Future<void> _resolveInitialScreen() async {
		await AuthSession.load();
		final onboardingCompleted = await OnboardingStorage.isCompleted();
		if (!mounted) {
			return;
		}

		final Widget nextScreen;
		if (!onboardingCompleted) {
			nextScreen = const OnboardingScreen();
		} else if (AuthSession.isAuthenticated && AuthSession.hasStoredPin) {
			final unlockedByBiometric = await _tryBiometricUnlock();
			if (!mounted) {
				return;
			}

			if (unlockedByBiometric) {
				nextScreen = const MainShellScreen();
			} else {
				nextScreen = PinCodeScreen(
					mode: PinCodeMode.entry,
					phoneDigits: AuthSession.pinPhoneDigits,
					tryBiometricOnOpen: true,
				);
			}
		} else if (AuthSession.isAuthenticated) {
			nextScreen = const MainShellScreen();
		} else {
			nextScreen = const PhoneLoginScreen();
		}

		if (!mounted) {
			return;
		}

		Navigator.of(context).pushReplacement(
			MaterialPageRoute(builder: (context) => nextScreen),
		);
	}

	Future<bool> _tryBiometricUnlock() async {
		if (!AuthSession.biometricEnabled) {
			return false;
		}

		final result = await _biometricAuthService.authenticate(
			reason: 'Войдите в Beauty Trust',
		);
		return result == BiometricUnlockResult.success;
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
