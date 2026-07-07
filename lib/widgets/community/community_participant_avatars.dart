import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CommunityParticipantAvatars extends StatelessWidget {
	const CommunityParticipantAvatars({
		super.key,
		required this.initials,
		this.maxVisible = 4,
		this.avatarSize = 28,
	});

	final List<String> initials;
	final int maxVisible;
	final double avatarSize;

	@override
	Widget build(BuildContext context) {
		final visibleInitials = initials.take(maxVisible).toList();
		final overlap = avatarSize * 0.32;

		return SizedBox(
			height: avatarSize,
			width: avatarSize + overlap * (visibleInitials.length - 1),
			child: Stack(
				children: [
					for (var index = 0; index < visibleInitials.length; index++)
						Positioned(
							left: index * overlap,
							child: _AvatarCircle(
								initial: visibleInitials[index],
								size: avatarSize,
								colorIndex: index,
							),
						),
				],
			),
		);
	}
}

class _AvatarCircle extends StatelessWidget {
	const _AvatarCircle({
		required this.initial,
		required this.size,
		required this.colorIndex,
	});

	final String initial;
	final double size;
	final int colorIndex;

	static const _colors = [
		AppColors.primary,
		AppColors.secondary,
		Color(0xFF60A5FA),
		Color(0xFFF472B6),
	];

	@override
	Widget build(BuildContext context) {
		final color = _colors[colorIndex % _colors.length];

		return Container(
			width: size,
			height: size,
			alignment: Alignment.center,
			decoration: BoxDecoration(
				color: AppColors.surfaceElevated,
				shape: BoxShape.circle,
				border: Border.all(color: AppColors.background, width: 2),
			),
			child: Text(
				initial,
				style: TextStyle(
					color: color,
					fontSize: size * 0.38,
					fontWeight: FontWeight.w700,
				),
			),
		);
	}
}
