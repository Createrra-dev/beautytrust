import 'package:flutter/material.dart';

import '../../models/support_ticket.dart';
import '../../theme/app_theme.dart';
import 'support_status_badge.dart';

class SupportTicketCard extends StatelessWidget {
	const SupportTicketCard({
		super.key,
		required this.ticket,
		required this.onOpen,
		this.referenceNow,
	});

	final SupportTicket ticket;
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
										const _SupportEmojiBadge(),
										const SizedBox(width: 12),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(
														ticket.title,
														maxLines: 2,
														overflow: TextOverflow.ellipsis,
														style: const TextStyle(
															color: AppColors.textPrimary,
															fontSize: 16,
															fontWeight: FontWeight.w600,
															height: 1.25,
														),
													),
													const SizedBox(height: 4),
													Text(
														'Обращение ${ticket.ticketNumber}',
														style: const TextStyle(
															color: AppColors.textMuted,
															fontSize: 13,
														),
													),
													const SizedBox(height: 6),
													Text(
														ticket.lastMessage,
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
													formatSupportTime(
														ticket.lastMessageAt,
														referenceNow: referenceNow,
													),
													style: const TextStyle(
														color: AppColors.textMuted,
														fontSize: 12,
													),
												),
												if (ticket.unreadCount > 0) ...[
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
																'${ticket.unreadCount}',
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
										SupportStatusBadge(status: ticket.status),
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

class _SupportEmojiBadge extends StatelessWidget {
	const _SupportEmojiBadge();

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
			child: const Text(
				'🛟',
				style: TextStyle(fontSize: 28),
			),
		);
	}
}
