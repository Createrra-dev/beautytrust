import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrimaryAuthButton extends StatelessWidget {
	const PrimaryAuthButton({
		super.key,
		required this.label,
		required this.onPressed,
	});

	final String label;
	final VoidCallback? onPressed;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: FilledButton(
				onPressed: onPressed,
				child: Text(label),
			),
		);
	}
}

class SocialAuthButton extends StatelessWidget {
	const SocialAuthButton({
		super.key,
		required this.label,
		required this.icon,
		required this.onPressed,
	});

	final String label;
	final IconData icon;
	final VoidCallback onPressed;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: OutlinedButton.icon(
				onPressed: onPressed,
				icon: Icon(icon, color: AppColors.textPrimary, size: 20),
				label: Text(
					label,
					style: const TextStyle(
						color: AppColors.textPrimary,
						fontWeight: FontWeight.w500,
					),
				),
				style: OutlinedButton.styleFrom(
					backgroundColor: AppColors.surface,
					side: const BorderSide(color: AppColors.border),
					padding: const EdgeInsets.symmetric(vertical: 14),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(12),
					),
				),
			),
		);
	}
}

class AuthDivider extends StatelessWidget {
	const AuthDivider({super.key});

	@override
	Widget build(BuildContext context) {
		return const Row(
			children: [
				Expanded(child: Divider(color: AppColors.border)),
				Padding(
					padding: EdgeInsets.symmetric(horizontal: 12),
					child: Text(
						'или',
						style: TextStyle(color: AppColors.textMuted),
					),
				),
				Expanded(child: Divider(color: AppColors.border)),
			],
		);
	}
}
