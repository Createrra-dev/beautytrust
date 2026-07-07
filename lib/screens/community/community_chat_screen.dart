import 'package:flutter/material.dart';

import '../../services/community_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/community_message_bubble.dart';

class CommunityChatScreen extends StatefulWidget {
	const CommunityChatScreen({
		super.key,
		required this.topicId,
	});

	static const routeName = '/community/chat';

	final String topicId;

	@override
	State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
	final _messageController = TextEditingController();
	final _scrollController = ScrollController();
	final _communityService = CommunityService.instance;

	@override
	void initState() {
		super.initState();
		_communityService.addListener(_onCommunityChanged);
		_communityService.markTopicRead(widget.topicId);
		_scrollToBottom();
	}

	@override
	void dispose() {
		_communityService.removeListener(_onCommunityChanged);
		_messageController.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	void _onCommunityChanged() {
		setState(() {});
	}

	void _sendMessage() {
		final message = _communityService.sendMessage(
			topicId: widget.topicId,
			text: _messageController.text,
		);

		if (message == null) {
			return;
		}

		_messageController.clear();
		_scrollToBottom();
	}

	void _scrollToBottom() {
		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!_scrollController.hasClients) {
				return;
			}

			_scrollController.animateTo(
				_scrollController.position.maxScrollExtent,
				duration: const Duration(milliseconds: 250),
				curve: Curves.easeOut,
			);
		});
	}

	@override
	Widget build(BuildContext context) {
		final topic = _communityService.topicById(widget.topicId);
		if (topic == null) {
			return const SafeArea(
				child: Center(
					child: Text(
						'Тема не найдена',
						style: TextStyle(color: AppColors.textMuted),
					),
				),
			);
		}

		final referenceNow = DateTime.now();
		final messages = _communityService.messagesForTopic(widget.topicId);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_ChatHeader(
						title: topic.title,
						participantCount: topic.participantCount,
					),
					Expanded(
						child: ListView.builder(
							controller: _scrollController,
							padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
							itemCount: messages.length,
							itemBuilder: (context, index) {
								return CommunityMessageBubble(
									message: messages[index],
									referenceNow: referenceNow,
								);
							},
						),
					),
					_MessageInputBar(
						controller: _messageController,
						onSend: _sendMessage,
						onChanged: (_) => setState(() {}),
					),
				],
			),
		);
	}
}

class _ChatHeader extends StatelessWidget {
	const _ChatHeader({
		required this.title,
		required this.participantCount,
	});

	final String title;
	final int participantCount;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
			decoration: const BoxDecoration(
				border: Border(
					bottom: BorderSide(color: AppColors.border),
				),
			),
			child: Row(
				children: [
					IconButton(
						onPressed: () => Navigator.of(context).pop(),
						icon: const Icon(
							Icons.arrow_back_ios_new_rounded,
							color: AppColors.textPrimary,
							size: 20,
						),
					),
					Expanded(
						child: Column(
							children: [
								Text(
									title,
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
									textAlign: TextAlign.center,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 16,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 2),
								Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										const Icon(
											Icons.people_outline_rounded,
											size: 14,
											color: AppColors.textMuted,
										),
										const SizedBox(width: 4),
										Text(
											'$participantCount участников',
											style: const TextStyle(
												color: AppColors.textMuted,
												fontSize: 12,
											),
										),
									],
								),
							],
						),
					),
					const SizedBox(width: 48),
				],
			),
		);
	}
}

class _MessageInputBar extends StatelessWidget {
	const _MessageInputBar({
		required this.controller,
		required this.onSend,
		required this.onChanged,
	});

	final TextEditingController controller;
	final VoidCallback onSend;
	final ValueChanged<String> onChanged;

	@override
	Widget build(BuildContext context) {
		final canSend = controller.text.trim().isNotEmpty;

		return Container(
			padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
			decoration: const BoxDecoration(
				color: AppColors.surface,
				border: Border(
					top: BorderSide(color: AppColors.border),
				),
			),
			child: Row(
				children: [
					Expanded(
						child: TextField(
							controller: controller,
							onChanged: onChanged,
							minLines: 1,
							maxLines: 4,
							style: const TextStyle(color: AppColors.textPrimary),
							decoration: InputDecoration(
								hintText: 'Напишите сообщение...',
								hintStyle: const TextStyle(color: AppColors.textMuted),
								filled: true,
								fillColor: AppColors.surfaceElevated,
								contentPadding: const EdgeInsets.symmetric(
									horizontal: 14,
									vertical: 10,
								),
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: BorderSide.none,
								),
							),
						),
					),
					const SizedBox(width: 8),
					Material(
						color: canSend ? AppColors.primary : AppColors.surfaceElevated,
						borderRadius: BorderRadius.circular(12),
						child: InkWell(
							onTap: canSend ? onSend : null,
							borderRadius: BorderRadius.circular(12),
							child: SizedBox(
								width: 44,
								height: 44,
								child: Icon(
									Icons.send_rounded,
									color: canSend
										? AppColors.textPrimary
										: AppColors.textMuted,
								),
							),
						),
					),
				],
			),
		);
	}
}
