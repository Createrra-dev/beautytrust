import 'package:flutter/material.dart';

import 'config/app_branding.dart';
import 'screens/app_launch_screen.dart';
import 'theme/app_theme.dart';

void main() {
	WidgetsFlutterBinding.ensureInitialized();
	runApp(const BeautyTrustApp());
}

class BeautyTrustApp extends StatelessWidget {
	const BeautyTrustApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: AppBranding.appName,
			theme: AppTheme.dark,
			home: const AppLaunchScreen(),
		);
	}
}
