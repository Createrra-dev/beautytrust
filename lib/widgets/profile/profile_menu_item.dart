import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProfileMenuItem extends StatelessWidget {
	const ProfileMenuItem({
		super.key,
		required this.icon,
		required this.title,
		this.trailingLabel,
		required this.onTap,
	});

	final IconData icon;
	final String title;
	final String? trailingLabel;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
					child: Row(
						children: [
							Icon(
								icon,
								size: 22,
								color: AppColors.textMuted,
							),
							const SizedBox(width: 14),
							Expanded(
								child: Text(
									title,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 16,
										fontWeight: FontWeight.w500,
									),
								),
							),
							if (trailingLabel != null) ...[
								Text(
									trailingLabel!,
									style: const TextStyle(
										color: AppColors.textMuted,
										fontSize: 14,
									),
								),
								const SizedBox(width: 6),
							],
							const Icon(
								Icons.chevron_right_rounded,
								color: AppColors.textMuted,
								size: 20,
							),
						],
					),
				),
			),
		);
	}
}
