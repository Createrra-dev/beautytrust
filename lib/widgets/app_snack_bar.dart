import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppSnackBarType {
	info,
	success,
	error,
}

class AppSnackBar {
	AppSnackBar._();

	static void show(
		BuildContext context,
		String message, {
		AppSnackBarType type = AppSnackBarType.info,
	}) {
		final accentColor = switch (type) {
			AppSnackBarType.success => AppColors.secondary,
			AppSnackBarType.error => AppColors.error,
			AppSnackBarType.info => AppColors.primary,
		};

		final icon = switch (type) {
			AppSnackBarType.success => Icons.check_circle_outline_rounded,
			AppSnackBarType.error => Icons.error_outline_rounded,
			AppSnackBarType.info => Icons.info_outline_rounded,
		};

		ScaffoldMessenger.of(context)
			..hideCurrentSnackBar()
			..showSnackBar(
				SnackBar(
					behavior: SnackBarBehavior.floating,
					backgroundColor: Colors.transparent,
					elevation: 0,
					margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
					padding: EdgeInsets.zero,
					content: Container(
						padding: const EdgeInsets.symmetric(
							horizontal: 14,
							vertical: 12,
						),
						decoration: BoxDecoration(
							color: AppColors.surfaceElevated,
							borderRadius: BorderRadius.circular(12),
							border: Border.all(
								color: accentColor.withValues(alpha: 0.45),
							),
						),
						child: Row(
							children: [
								Icon(
									icon,
									color: accentColor,
									size: 20,
								),
								const SizedBox(width: 10),
								Expanded(
									child: Text(
										message,
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 14,
											fontWeight: FontWeight.w500,
											height: 1.35,
										),
									),
								),
							],
						),
					),
				),
			);
	}
}
