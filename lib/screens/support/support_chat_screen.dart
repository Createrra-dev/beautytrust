import 'package:flutter/material.dart';

import '../../models/support_ticket.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/community/community_message_bubble.dart';
import '../../widgets/support/support_status_badge.dart';

class SupportChatScreen extends StatefulWidget {
	const SupportChatScreen({
		super.key,
		required this.ticketId,
	});

	static const routeName = '/support/chat';

	final String ticketId;

	@override
	State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
	final _messageController = TextEditingController();
	final _scrollController = ScrollController();
	final _supportService = SupportService.instance;

	@override
	void initState() {
		super.initState();
		_supportService.addListener(_onSupportChanged);
		_supportService.loadMessages(widget.ticketId);
	}

	@override
	void dispose() {
		_supportService.removeListener(_onSupportChanged);
		_messageController.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	void _onSupportChanged() {
		setState(() {});
		_scrollToBottom();
	}

	void _sendMessage() async {
		final message = await _supportService.sendMessage(
			ticketId: widget.ticketId,
			text: _messageController.text,
		);

		if (message == null) {
			return;
		}

		_messageController.clear();
		_scrollToBottom();
	}

	void _cancelTicket() async {
		final cancelled = await _supportService.cancelTicket(widget.ticketId);
		if (!mounted || !cancelled) {
			return;
		}

		AppSnackBar.show(
			context,
			'Обращение отменено',
			type: AppSnackBarType.info,
		);
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
		final ticket = _supportService.ticketById(widget.ticketId);
		if (ticket == null) {
			return const SafeArea(
				child: Center(
					child: Text(
						'Обращение не найдено',
						style: TextStyle(color: AppColors.textMuted),
					),
				),
			);
		}

		final referenceNow = DateTime.now();
		final messages = _supportService.messagesForTicket(widget.ticketId);
		final canSendMessage = ticket.status.isOpen;

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_ChatHeader(
						title: ticket.title,
						ticketNumber: ticket.ticketNumber,
						status: ticket.status,
						onCancel: ticket.status.isOpen ? _cancelTicket : null,
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
					if (!canSendMessage)
						const _ClosedTicketNotice()
					else
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
		required this.ticketNumber,
		required this.status,
		this.onCancel,
	});

	final String title;
	final String ticketNumber;
	final SupportTicketStatus status;
	final VoidCallback? onCancel;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
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
								const SizedBox(height: 4),
								Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Text(
											'Обращение $ticketNumber',
											style: const TextStyle(
												color: AppColors.textMuted,
												fontSize: 12,
											),
										),
										const SizedBox(width: 8),
										SupportStatusBadge(status: status),
									],
								),
							],
						),
					),
					if (onCancel != null)
						IconButton(
							onPressed: onCancel,
							tooltip: 'Отменить обращение',
							icon: const Icon(
								Icons.close_rounded,
								color: AppColors.textMuted,
								size: 22,
							),
						)
					else
						const SizedBox(width: 48),
				],
			),
		);
	}
}

class _ClosedTicketNotice extends StatelessWidget {
	const _ClosedTicketNotice();

	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
			color: AppColors.surface,
			child: const Text(
				'Это обращение закрыто. Новые сообщения отправить нельзя.',
				textAlign: TextAlign.center,
				style: TextStyle(
					color: AppColors.textMuted,
					fontSize: 13,
				),
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
