import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class MasterAvatar extends StatelessWidget {
	const MasterAvatar({
		super.key,
		required this.firstName,
		this.avatarPath,
		this.avatarUrl,
		this.radius = 44,
		this.onTap,
		this.isLoading = false,
	});

	final String firstName;
	final String? avatarPath;
	final String? avatarUrl;
	final double radius;
	final VoidCallback? onTap;
	final bool isLoading;

	@override
	Widget build(BuildContext context) {
		final imageProvider = _imageProvider();

		return GestureDetector(
			onTap: isLoading ? null : onTap,
			child: Stack(
				clipBehavior: Clip.none,
				children: [
					Container(
						decoration: BoxDecoration(
							shape: BoxShape.circle,
							border: Border.all(
								color: AppColors.border,
								width: 2,
							),
						),
						child: CircleAvatar(
							radius: radius,
							backgroundColor: AppColors.surfaceElevated,
							backgroundImage: imageProvider,
							child: imageProvider == null
								? Text(
									_firstLetter(firstName),
									style: TextStyle(
										color: AppColors.textPrimary,
										fontSize: radius * 0.72,
										fontWeight: FontWeight.w600,
									),
								)
								: null,
						),
					),
					if (onTap != null)
						Positioned(
							right: 0,
							bottom: 0,
							child: Container(
								width: 30,
								height: 30,
								decoration: BoxDecoration(
									color: AppColors.primary,
									shape: BoxShape.circle,
									border: Border.all(
										color: AppColors.background,
										width: 2,
									),
								),
								child: const Icon(
									Icons.photo_camera_outlined,
									color: AppColors.textPrimary,
									size: 16,
								),
							),
						),
					if (isLoading)
						Positioned.fill(
							child: Container(
								decoration: BoxDecoration(
									color: Colors.black.withValues(alpha: 0.35),
									shape: BoxShape.circle,
								),
								child: const Center(
									child: SizedBox(
										width: 24,
										height: 24,
										child: CircularProgressIndicator(
											strokeWidth: 2,
											color: AppColors.textPrimary,
										),
									),
								),
							),
						),
				],
			),
		);
	}

	ImageProvider? _imageProvider() {
		final path = avatarPath;
		if (path != null && path.isNotEmpty) {
			final file = File(path);
			if (file.existsSync()) {
				return FileImage(file);
			}
		}

		final url = avatarUrl;
		if (url != null && url.isNotEmpty) {
			return NetworkImage(url);
		}

		return null;
	}

	String _firstLetter(String name) {
		final trimmedName = name.trim();
		if (trimmedName.isEmpty) {
			return '?';
		}

		return trimmedName.substring(0, 1).toUpperCase();
	}
}
