import 'package:flutter/material.dart';

import '../../models/community_topic.dart';
import '../../theme/app_theme.dart';
import 'community_participant_avatars.dart';

class CommunityTopicCard extends StatelessWidget {
	const CommunityTopicCard({
		super.key,
		required this.topic,
		required this.onOpen,
		this.referenceNow,
	});

	final CommunityTopic topic;
	final VoidCallback onOpen;
	final DateTime? referenceNow;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.surface,
			borderRadius: BorderRadius.circular(16),
			child: InkWell(
				onTap: onOpen,
				borderRadius: BorderRadius.circular(16),
				child: Ink(
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: AppColors.border),
					),
					child: Padding(
						padding: const EdgeInsets.all(14),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								Row(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										_TopicEmojiBadge(emoji: topic.emoji),
										const SizedBox(width: 12),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Row(
														children: [
															Expanded(
																child: Text(
																	topic.title,
																	maxLines: 2,
																	overflow: TextOverflow.ellipsis,
																	style: const TextStyle(
																		color: AppColors.textPrimary,
																		fontSize: 16,
																		fontWeight: FontWeight.w600,
																		height: 1.25,
																	),
																),
															),
															if (topic.isPinned) ...[
																const SizedBox(width: 6),
																const Icon(
																	Icons.push_pin_rounded,
																	size: 16,
																	color: AppColors.primary,
																),
															],
														],
													),
													const SizedBox(height: 4),
													Text(
														topic.authorName,
														style: const TextStyle(
															color: AppColors.textMuted,
															fontSize: 13,
														),
													),
													const SizedBox(height: 6),
													Text(
														topic.lastMessage,
														maxLines: 2,
														overflow: TextOverflow.ellipsis,
														style: const TextStyle(
															color: AppColors.textMuted,
															fontSize: 14,
															height: 1.35,
														),
													),
												],
											),
										),
										const SizedBox(width: 8),
										Column(
											crossAxisAlignment: CrossAxisAlignment.end,
											children: [
												Text(
													formatCommunityTime(
														topic.lastMessageAt,
														referenceNow: referenceNow,
													),
													style: const TextStyle(
														color: AppColors.textMuted,
														fontSize: 12,
													),
												),
												if (topic.unreadCount > 0) ...[
													const SizedBox(height: 10),
													ConstrainedBox(
														constraints: const BoxConstraints(
															minWidth: 22,
															minHeight: 22,
														),
														child: Container(
															padding: const EdgeInsets.symmetric(
																horizontal: 6,
																vertical: 2,
															),
															alignment: Alignment.center,
															decoration: BoxDecoration(
																color: AppColors.primary,
																borderRadius: BorderRadius.circular(12),
															),
															child: Text(
																'${topic.unreadCount}',
																style: const TextStyle(
																	color: AppColors.textPrimary,
																	fontSize: 12,
																	fontWeight: FontWeight.w600,
																),
															),
														),
													),
												],
											],
										),
									],
								),
								const SizedBox(height: 14),
								Row(
									children: [
										CommunityParticipantAvatars(
											initials: topic.participantInitials,
										),
										const SizedBox(width: 8),
										Text(
											'+ ${topic.participantCount}',
											style: const TextStyle(
												color: AppColors.textMuted,
												fontSize: 12,
												fontWeight: FontWeight.w500,
											),
										),
										const Spacer(),
										FilledButton(
											onPressed: onOpen,
											style: FilledButton.styleFrom(
												minimumSize: const Size(0, 36),
												padding: const EdgeInsets.symmetric(horizontal: 18),
												textStyle: const TextStyle(
													fontSize: 14,
													fontWeight: FontWeight.w600,
												),
											),
											child: const Text('Открыть'),
										),
									],
								),
							],
						),
					),
				),
			),
		);
	}
}

class _TopicEmojiBadge extends StatelessWidget {
	const _TopicEmojiBadge({required this.emoji});

	final String emoji;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 56,
			height: 56,
			alignment: Alignment.center,
			decoration: BoxDecoration(
				color: AppColors.surfaceElevated,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(
					color: AppColors.primary.withValues(alpha: 0.35),
				),
			),
			child: Text(
				emoji,
				style: const TextStyle(fontSize: 28),
			),
		);
	}
}
