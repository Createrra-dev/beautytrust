import 'package:flutter/material.dart';

import '../../models/community_message.dart';
import '../../models/community_topic.dart';
import '../../theme/app_theme.dart';

class CommunityMessageBubble extends StatelessWidget {
	const CommunityMessageBubble({
		super.key,
		required this.message,
		this.referenceNow,
	});

	final CommunityMessage message;
	final DateTime? referenceNow;

	@override
	Widget build(BuildContext context) {
		if (message.isMine) {
			return _MineBubble(
				message: message,
				referenceNow: referenceNow,
			);
		}

		return _OtherBubble(
			message: message,
			referenceNow: referenceNow,
		);
	}
}

class _MineBubble extends StatelessWidget {
	const _MineBubble({
		required this.message,
		this.referenceNow,
	});

	final CommunityMessage message;
	final DateTime? referenceNow;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.only(left: 56, bottom: 12),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.end,
				crossAxisAlignment: CrossAxisAlignment.end,
				children: [
					Flexible(
						child: Container(
							padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
							decoration: BoxDecoration(
								color: AppColors.primary,
								borderRadius: const BorderRadius.only(
									topLeft: Radius.circular(16),
									topRight: Radius.circular(16),
									bottomLeft: Radius.circular(16),
									bottomRight: Radius.circular(4),
								),
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.end,
								children: [
									Text(
										message.text,
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 15,
											height: 1.4,
										),
									),
									const SizedBox(height: 4),
									Text(
										formatCommunityTime(
											message.sentAt,
											referenceNow: referenceNow,
										),
										style: TextStyle(
											color: AppColors.textPrimary.withValues(alpha: 0.7),
											fontSize: 11,
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}
}

class _OtherBubble extends StatelessWidget {
	const _OtherBubble({
		required this.message,
		this.referenceNow,
	});

	final CommunityMessage message;
	final DateTime? referenceNow;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.only(right: 56, bottom: 12),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.end,
				children: [
					_AuthorAvatar(name: message.authorName),
					const SizedBox(width: 8),
					Flexible(
						child: Container(
							padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
							decoration: BoxDecoration(
								color: AppColors.surface,
								borderRadius: const BorderRadius.only(
									topLeft: Radius.circular(16),
									topRight: Radius.circular(16),
									bottomLeft: Radius.circular(4),
									bottomRight: Radius.circular(16),
								),
								border: Border.all(color: AppColors.border),
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										message.authorName,
										style: const TextStyle(
											color: AppColors.primary,
											fontSize: 12,
											fontWeight: FontWeight.w600,
										),
									),
									const SizedBox(height: 4),
									Text(
										message.text,
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 15,
											height: 1.4,
										),
									),
									const SizedBox(height: 4),
									Text(
										formatCommunityTime(
											message.sentAt,
											referenceNow: referenceNow,
										),
										style: const TextStyle(
											color: AppColors.textMuted,
											fontSize: 11,
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}
}

class _AuthorAvatar extends StatelessWidget {
	const _AuthorAvatar({required this.name});

	final String name;

	@override
	Widget build(BuildContext context) {
		final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

		return Container(
			width: 36,
			height: 36,
			alignment: Alignment.center,
			decoration: BoxDecoration(
				color: AppColors.surfaceElevated,
				shape: BoxShape.circle,
				border: Border.all(color: AppColors.border),
			),
			child: Text(
				initial,
				style: const TextStyle(
					color: AppColors.secondary,
					fontSize: 14,
					fontWeight: FontWeight.w700,
				),
			),
		);
	}
}
