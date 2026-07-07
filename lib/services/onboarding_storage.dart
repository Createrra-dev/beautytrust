import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
	OnboardingStorage._();

	static const _completedKey = 'onboarding_completed';

	static Future<bool> isCompleted() async {
		final preferences = await SharedPreferences.getInstance();
		return preferences.getBool(_completedKey) ?? false;
	}

	static Future<void> markCompleted() async {
		final preferences = await SharedPreferences.getInstance();
		await preferences.setBool(_completedKey, true);
	}
}
