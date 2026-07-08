import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum AvatarPickerAction {
	camera,
	gallery,
	remove,
}

Future<AvatarPickerAction?> showAvatarPickerSheet(
	BuildContext context, {
	bool canRemove = false,
}) {
	return showModalBottomSheet<AvatarPickerAction>(
		context: context,
		backgroundColor: AppColors.surfaceElevated,
		shape: const RoundedRectangleBorder(
			borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
		),
		builder: (context) {
			return SafeArea(
				child: Padding(
					padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							Center(
								child: Container(
									width: 40,
									height: 4,
									decoration: BoxDecoration(
										color: AppColors.border,
										borderRadius: BorderRadius.circular(2),
									),
								),
							),
							const SizedBox(height: 16),
							const Text(
								'Фото профиля',
								textAlign: TextAlign.center,
								style: TextStyle(
									color: AppColors.textPrimary,
									fontSize: 18,
									fontWeight: FontWeight.w600,
								),
							),
							const SizedBox(height: 16),
							_AvatarPickerOption(
								icon: Icons.photo_camera_outlined,
								title: 'Сфотографировать',
								onTap: () {
									Navigator.of(context).pop(AvatarPickerAction.camera);
								},
							),
							const SizedBox(height: 8),
							_AvatarPickerOption(
								icon: Icons.photo_library_outlined,
								title: 'Выбрать из галереи',
								onTap: () {
									Navigator.of(context).pop(AvatarPickerAction.gallery);
								},
							),
							if (canRemove) ...[
								const SizedBox(height: 8),
								_AvatarPickerOption(
									icon: Icons.delete_outline_rounded,
									title: 'Удалить фото',
									isDestructive: true,
									onTap: () {
										Navigator.of(context).pop(AvatarPickerAction.remove);
									},
								),
							],
						],
					),
				),
			);
		},
	);
}

class _AvatarPickerOption extends StatelessWidget {
	const _AvatarPickerOption({
		required this.icon,
		required this.title,
		required this.onTap,
		this.isDestructive = false,
	});

	final IconData icon;
	final String title;
	final VoidCallback onTap;
	final bool isDestructive;

	@override
	Widget build(BuildContext context) {
		final color = isDestructive ? AppColors.error : AppColors.primary;

		return Material(
			color: AppColors.surface,
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(14),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: AppColors.border),
					),
					child: Row(
						children: [
							Icon(icon, color: color, size: 22),
							const SizedBox(width: 12),
							Expanded(
								child: Text(
									title,
									style: TextStyle(
										color: isDestructive ? AppColors.error : AppColors.textPrimary,
										fontSize: 16,
										fontWeight: FontWeight.w500,
									),
								),
							),
							const Icon(
								Icons.chevron_right_rounded,
								color: AppColors.textMuted,
								size: 22,
							),
						],
					),
				),
			),
		);
	}
}
