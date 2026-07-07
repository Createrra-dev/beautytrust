import 'package:flutter/material.dart';

import 'community_topic.dart';

enum SupportTicketStatus {
	newTicket,
	inProgress,
	waitingForResponse,
	closed,
	cancelled,
}

extension SupportTicketStatusX on SupportTicketStatus {
	String get label {
		return switch (this) {
			SupportTicketStatus.newTicket => 'Новое',
			SupportTicketStatus.inProgress => 'В работе',
			SupportTicketStatus.waitingForResponse => 'Ожидание ответа',
			SupportTicketStatus.closed => 'Закрыто',
			SupportTicketStatus.cancelled => 'Отменено',
		};
	}

	Color color(Color primary, Color secondary, Color muted, Color error, Color warning) {
		return switch (this) {
			SupportTicketStatus.newTicket => primary,
			SupportTicketStatus.inProgress => secondary,
			SupportTicketStatus.waitingForResponse => warning,
			SupportTicketStatus.closed => muted,
			SupportTicketStatus.cancelled => error,
		};
	}

	bool get isOpen {
		return this != SupportTicketStatus.closed &&
			this != SupportTicketStatus.cancelled;
	}
}

class SupportTicket {
	const SupportTicket({
		required this.id,
		required this.title,
		required this.authorName,
		required this.createdAt,
		required this.lastMessage,
		required this.lastMessageAt,
		required this.status,
		this.unreadCount = 0,
	});

	final String id;
	final String title;
	final String authorName;
	final DateTime createdAt;
	final String lastMessage;
	final DateTime lastMessageAt;
	final SupportTicketStatus status;
	final int unreadCount;

	String get ticketNumber => '#${id.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}';

	SupportTicket copyWith({
		String? lastMessage,
		DateTime? lastMessageAt,
		SupportTicketStatus? status,
		int? unreadCount,
	}) {
		return SupportTicket(
			id: id,
			title: title,
			authorName: authorName,
			createdAt: createdAt,
			lastMessage: lastMessage ?? this.lastMessage,
			lastMessageAt: lastMessageAt ?? this.lastMessageAt,
			status: status ?? this.status,
			unreadCount: unreadCount ?? this.unreadCount,
		);
	}
}

String formatSupportTime(DateTime dateTime, {DateTime? referenceNow}) {
	return formatCommunityTime(dateTime, referenceNow: referenceNow);
}
