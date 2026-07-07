import 'package:flutter/foundation.dart';

import '../models/community_message.dart';
import '../models/support_ticket.dart';
import 'api/app_api_repository.dart';

class SupportService extends ChangeNotifier {
	SupportService._();

	static final SupportService instance = SupportService._();
	static final AppApiRepository _api = AppApiRepository();

	final List<SupportTicket> _tickets = [];
	final Map<String, List<CommunityMessage>> _messagesByTicket = {};

	Future<void> syncFromApi({String query = ''}) async {
		_tickets
			..clear()
			..addAll(await _api.fetchSupportTickets(query: query));
		notifyListeners();
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
		return List<CommunityMessage>.from(_messagesByTicket[ticketId] ?? const []);
	}

	SupportTicket? ticketById(String ticketId) {
		for (final ticket in _tickets) {
			if (ticket.id == ticketId) {
				return ticket;
			}
		}
		return null;
	}

	Future<SupportTicket> createTicket({
		required String title,
		required String description,
	}) async {
		final ticket = await _api.createSupportTicket(
			title: title,
			description: description,
		);
		_tickets.insert(0, ticket);
		notifyListeners();
		await loadMessages(ticket.id);
		return ticket;
	}

	Future<void> loadMessages(String ticketId) async {
		_messagesByTicket[ticketId] = await _api.fetchSupportMessages(ticketId);
		markTicketRead(ticketId);
		notifyListeners();
	}

	Future<CommunityMessage?> sendMessage({
		required String ticketId,
		required String text,
	}) async {
		final trimmedText = text.trim();
		if (trimmedText.isEmpty) {
			return null;
		}

		final ticket = ticketById(ticketId);
		if (ticket == null || !ticket.status.isOpen) {
			return null;
		}

		final message = await _api.sendSupportMessage(ticketId: ticketId, text: trimmedText);
		await syncFromApi();
		await loadMessages(ticketId);
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

	Future<bool> cancelTicket(String ticketId) async {
		final ticket = ticketById(ticketId);
		if (ticket == null || !ticket.status.isOpen) {
			return false;
		}

		await _api.cancelSupportTicket(ticketId);
		await syncFromApi();
		return true;
	}
}
