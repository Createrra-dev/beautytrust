import 'package:flutter/foundation.dart';

import '../models/community_message.dart';
import '../models/community_topic.dart';
import 'api/app_api_repository.dart';

class CommunityService extends ChangeNotifier {
	CommunityService._();

	static final CommunityService instance = CommunityService._();
	static final AppApiRepository _api = AppApiRepository();

	final List<CommunityTopic> _topics = [];
	final Map<String, List<CommunityMessage>> _messagesByTopic = {};

	Future<void> syncFromApi({String query = ''}) async {
		_topics
			..clear()
			..addAll(await _api.fetchCommunityTopics(query: query));
		notifyListeners();
	}

	List<CommunityTopic> topicsFor(String query) {
		final normalizedQuery = query.trim().toLowerCase();
		final sortedTopics = List<CommunityTopic>.from(_topics)
			..sort((left, right) {
				if (left.isPinned != right.isPinned) {
					return left.isPinned ? -1 : 1;
				}
				return right.lastMessageAt.compareTo(left.lastMessageAt);
			});

		if (normalizedQuery.isEmpty) {
			return sortedTopics;
		}

		return sortedTopics.where((topic) {
			return topic.title.toLowerCase().contains(normalizedQuery) ||
				topic.lastMessage.toLowerCase().contains(normalizedQuery) ||
				topic.authorName.toLowerCase().contains(normalizedQuery);
		}).toList();
	}

	List<CommunityMessage> messagesForTopic(String topicId) {
		return List<CommunityMessage>.from(_messagesByTopic[topicId] ?? const []);
	}

	CommunityTopic? topicById(String topicId) {
		for (final topic in _topics) {
			if (topic.id == topicId) {
				return topic;
			}
		}
		return null;
	}

	Future<CommunityTopic> createTopic({
		required String title,
		required String story,
	}) async {
		final topic = await _api.createCommunityTopic(title: title, story: story);
		_topics.insert(0, topic);
		_messagesByTopic[topic.id] = [
			CommunityMessage(
				id: 'local-${topic.id}',
				topicId: topic.id,
				authorName: topic.authorName,
				text: story.trim(),
				sentAt: topic.lastMessageAt,
				isMine: true,
			),
		];
		notifyListeners();
		return topic;
	}

	Future<void> loadMessages(String topicId) async {
		_messagesByTopic[topicId] = await _api.fetchCommunityMessages(topicId);
		markTopicRead(topicId);
		notifyListeners();
	}

	Future<CommunityMessage?> sendMessage({
		required String topicId,
		required String text,
	}) async {
		final trimmedText = text.trim();
		if (trimmedText.isEmpty) {
			return null;
		}

		final message = await _api.sendCommunityMessage(topicId: topicId, text: trimmedText);
		final messages = _messagesByTopic.putIfAbsent(topicId, () => []);
		messages.add(message);

		final topicIndex = _topics.indexWhere((topic) => topic.id == topicId);
		if (topicIndex >= 0) {
			final topic = _topics[topicIndex];
			_topics[topicIndex] = topic.copyWith(
				lastMessage: trimmedText,
				lastMessageAt: message.sentAt,
				unreadCount: 0,
			);
		}

		notifyListeners();
		return message;
	}

	void markTopicRead(String topicId) {
		final topicIndex = _topics.indexWhere((topic) => topic.id == topicId);
		if (topicIndex < 0) {
			return;
		}

		final topic = _topics[topicIndex];
		if (topic.unreadCount == 0) {
			return;
		}

		_topics[topicIndex] = topic.copyWith(unreadCount: 0);
		notifyListeners();
	}
}
