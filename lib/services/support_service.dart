import 'package:flutter/foundation.dart';

import '../data/demo_support_data.dart';
import '../models/community_message.dart';
import '../models/support_ticket.dart';

class SupportService extends ChangeNotifier {
	SupportService._() {
		_resetFromDemo();
	}

	static final SupportService instance = SupportService._();

	final List<SupportTicket> _tickets = [];
	final Map<String, List<CommunityMessage>> _messagesByTicket = {};
	var _nextTicketId = 100;
	var _nextMessageId = 5000;

	void _resetFromDemo({DateTime? referenceNow}) {
		_tickets
			..clear()
			..addAll(DemoSupportData.tickets(referenceNow: referenceNow));

		_messagesByTicket
			..clear()
			..addAll(DemoSupportData.messagesByTicket(referenceNow: referenceNow));
	}

	List<SupportTicket> ticketsFor(String query) {
		final normalizedQuery = query.trim().toLowerCase();
		final sortedTickets = List<SupportTicket>.from(_tickets)
			..sort((left, right) => right.lastMessageAt.compareTo(left.lastMessageAt));

		if (normalizedQuery.isEmpty) {
			return sortedTickets;
		}

		return sortedTickets.where((ticket) {
			return ticket.title.toLowerCase().contains(normalizedQuery) ||
				ticket.lastMessage.toLowerCase().contains(normalizedQuery) ||
				ticket.ticketNumber.contains(normalizedQuery);
		}).toList();
	}

	List<CommunityMessage> messagesForTicket(String ticketId) {
		return List<CommunityMessage>.from(
			_messagesByTicket[ticketId] ?? const [],
		);
	}

	SupportTicket? ticketById(String ticketId) {
		for (final ticket in _tickets) {
			if (ticket.id == ticketId) {
				return ticket;
			}
		}

		return null;
	}

	SupportTicket createTicket({
		required String title,
		required String description,
	}) {
		final now = DateTime.now();
		final ticketId = 'support-$_nextTicketId';
		_nextTicketId += 1;

		final messageId = 's-$_nextMessageId';
		_nextMessageId += 1;

		final ticket = SupportTicket(
			id: ticketId,
			title: title.trim(),
			authorName: DemoSupportData.currentUserName,
			createdAt: now,
			lastMessage: description.trim(),
			lastMessageAt: now,
			status: SupportTicketStatus.newTicket,
		);

		final message = CommunityMessage(
			id: messageId,
			topicId: ticketId,
			authorName: DemoSupportData.currentUserName,
			text: description.trim(),
			sentAt: now,
			isMine: true,
		);

		_tickets.insert(0, ticket);
		_messagesByTicket[ticketId] = [message];
		notifyListeners();
		_scheduleAdminReply(ticketId);
		return ticket;
	}

	CommunityMessage? sendMessage({
		required String ticketId,
		required String text,
	}) {
		final trimmedText = text.trim();
		if (trimmedText.isEmpty) {
			return null;
		}

		final ticketIndex = _tickets.indexWhere((ticket) => ticket.id == ticketId);
		if (ticketIndex < 0) {
			return null;
		}

		final ticket = _tickets[ticketIndex];
		if (!ticket.status.isOpen) {
			return null;
		}

		final now = DateTime.now();
		final messageId = 's-$_nextMessageId';
		_nextMessageId += 1;

		final message = CommunityMessage(
			id: messageId,
			topicId: ticketId,
			authorName: DemoSupportData.currentUserName,
			text: trimmedText,
			sentAt: now,
			isMine: true,
		);

		final messages = _messagesByTicket.putIfAbsent(ticketId, () => []);
		messages.add(message);

		_tickets[ticketIndex] = ticket.copyWith(
			lastMessage: trimmedText,
			lastMessageAt: now,
			status: SupportTicketStatus.waitingForResponse,
			unreadCount: 0,
		);

		notifyListeners();
		_scheduleAdminReply(ticketId);
		return message;
	}

	void markTicketRead(String ticketId) {
		final ticketIndex = _tickets.indexWhere((ticket) => ticket.id == ticketId);
		if (ticketIndex < 0) {
			return;
		}

		final ticket = _tickets[ticketIndex];
		if (ticket.unreadCount == 0) {
			return;
		}

		_tickets[ticketIndex] = ticket.copyWith(unreadCount: 0);
		notifyListeners();
	}

	bool cancelTicket(String ticketId) {
		final ticketIndex = _tickets.indexWhere((ticket) => ticket.id == ticketId);
		if (ticketIndex < 0) {
			return false;
		}

		final ticket = _tickets[ticketIndex];
		if (!ticket.status.isOpen) {
			return false;
		}

		_tickets[ticketIndex] = ticket.copyWith(
			status: SupportTicketStatus.cancelled,
		);
		notifyListeners();
		return true;
	}

	void _scheduleAdminReply(String ticketId) {
		Future<void>.delayed(const Duration(seconds: 2), () {
			_addAdminReply(ticketId);
		});
	}

	void _addAdminReply(String ticketId) {
		final ticketIndex = _tickets.indexWhere((ticket) => ticket.id == ticketId);
		if (ticketIndex < 0) {
			return;
		}

		final ticket = _tickets[ticketIndex];
		if (!ticket.status.isOpen) {
			return;
		}

		final now = DateTime.now();
		final messageId = 's-$_nextMessageId';
		_nextMessageId += 1;

		const replyText =
			'Спасибо за обращение! Мы уже смотрим ваш вопрос и скоро вернёмся с ответом.';

		final message = CommunityMessage(
			id: messageId,
			topicId: ticketId,
			authorName: DemoSupportData.supportAgentName,
			text: replyText,
			sentAt: now,
			isMine: false,
		);

		final messages = _messagesByTicket.putIfAbsent(ticketId, () => []);
		messages.add(message);

		_tickets[ticketIndex] = ticket.copyWith(
			lastMessage: replyText,
			lastMessageAt: now,
			status: SupportTicketStatus.inProgress,
			unreadCount: ticket.unreadCount + 1,
		);

		notifyListeners();
	}
}
