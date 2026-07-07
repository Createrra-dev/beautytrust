import 'package:flutter/material.dart';

class AppColors {
	AppColors._();

	static const background = Color(0xFF121217);
	static const surface = Color(0xFF1E1E26);
	static const surfaceElevated = Color(0xFF26262F);
	static const primary = Color(0xFF8A4FFF);
	static const secondary = Color(0xFF34D399);
	static const textPrimary = Color(0xFFFFFFFF);
	static const textMuted = Color(0xFF9CA3AF);
	static const border = Color(0xFF2F2F3A);
	static const keypadPlate = Color(0xFF2A2A35);
	static const error = Color(0xFFF87171);
	static const warning = Color(0xFFFBBF24);

	static const brandGradient = LinearGradient(
		begin: Alignment.centerLeft,
		end: Alignment.centerRight,
		colors: [primary, secondary],
	);

	static const glowGradient = RadialGradient(
		center: Alignment(-0.6, -0.8),
		radius: 1.2,
		colors: [
			Color(0x338A4FFF),
			Color(0x00121217),
		],
	);

	static const glowGradientSecondary = RadialGradient(
		center: Alignment(0.8, 0.9),
		radius: 1.0,
		colors: [
			Color(0x2234D399),
			Color(0x00121217),
		],
	);
}

class AppTheme {
	AppTheme._();

	static ThemeData get dark {
		const colorScheme = ColorScheme.dark(
			brightness: Brightness.dark,
			primary: AppColors.primary,
			onPrimary: AppColors.textPrimary,
			secondary: AppColors.secondary,
			onSecondary: AppColors.background,
			surface: AppColors.surface,
			onSurface: AppColors.textPrimary,
			error: AppColors.error,
			onError: AppColors.textPrimary,
		);

		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.dark,
			colorScheme: colorScheme,
			scaffoldBackgroundColor: AppColors.background,
			appBarTheme: const AppBarTheme(
				backgroundColor: AppColors.background,
				foregroundColor: AppColors.textPrimary,
				elevation: 0,
				centerTitle: true,
				titleTextStyle: TextStyle(
					color: AppColors.textPrimary,
					fontSize: 18,
					fontWeight: FontWeight.w600,
				),
			),
			cardTheme: CardThemeData(
				color: AppColors.surface,
				elevation: 0,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(16),
					side: const BorderSide(color: AppColors.border),
				),
			),
			dialogTheme: DialogThemeData(
				backgroundColor: AppColors.surfaceElevated,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(16),
				),
				titleTextStyle: const TextStyle(
					color: AppColors.textPrimary,
					fontSize: 20,
					fontWeight: FontWeight.w600,
				),
				contentTextStyle: const TextStyle(
					color: AppColors.textMuted,
					fontSize: 15,
					height: 1.4,
				),
			),
			textButtonTheme: TextButtonThemeData(
				style: TextButton.styleFrom(
					foregroundColor: AppColors.primary,
				),
			),
			filledButtonTheme: FilledButtonThemeData(
				style: FilledButton.styleFrom(
					backgroundColor: AppColors.primary,
					foregroundColor: AppColors.textPrimary,
					disabledBackgroundColor: AppColors.surfaceElevated,
					disabledForegroundColor: AppColors.textMuted,
					padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(12),
					),
					textStyle: const TextStyle(
						fontSize: 18,
						fontWeight: FontWeight.w600,
					),
				),
			),
			progressIndicatorTheme: const ProgressIndicatorThemeData(
				color: AppColors.primary,
			),
			textTheme: const TextTheme(
				bodyLarge: TextStyle(color: AppColors.textPrimary),
				bodyMedium: TextStyle(color: AppColors.textMuted),
				bodySmall: TextStyle(color: AppColors.textMuted),
				titleLarge: TextStyle(
					color: AppColors.textPrimary,
					fontWeight: FontWeight.bold,
				),
			),
		);
	}
}
