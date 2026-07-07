import 'package:flutter/foundation.dart';

import '../data/demo_community_data.dart';
import '../models/community_message.dart';
import '../models/community_topic.dart';

class CommunityService extends ChangeNotifier {
	CommunityService._() {
		_resetFromDemo();
	}

	static final CommunityService instance = CommunityService._();

	final List<CommunityTopic> _topics = [];
	final Map<String, List<CommunityMessage>> _messagesByTopic = {};
	var _nextTopicId = 100;
	var _nextMessageId = 1000;

	void _resetFromDemo({DateTime? referenceNow}) {
		_topics
			..clear()
			..addAll(DemoCommunityData.topics(referenceNow: referenceNow));

		_messagesByTopic
			..clear()
			..addAll(DemoCommunityData.messagesByTopic(referenceNow: referenceNow));
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
		return List<CommunityMessage>.from(
			_messagesByTopic[topicId] ?? const [],
		);
	}

	CommunityTopic? topicById(String topicId) {
		for (final topic in _topics) {
			if (topic.id == topicId) {
				return topic;
			}
		}

		return null;
	}

	CommunityTopic createTopic({
		required String title,
		required String story,
	}) {
		final now = DateTime.now();
		final topicId = 'topic-$_nextTopicId';
		_nextTopicId += 1;

		final messageId = 'm-$_nextMessageId';
		_nextMessageId += 1;

		final topic = CommunityTopic(
			id: topicId,
			title: title.trim(),
			authorName: DemoCommunityData.currentUserName,
			createdAt: now,
			participantCount: 1,
			lastMessage: story.trim(),
			lastMessageAt: now,
			participantInitials: ['А'],
			emoji: '✨',
		);

		final message = CommunityMessage(
			id: messageId,
			topicId: topicId,
			authorName: DemoCommunityData.currentUserName,
			text: story.trim(),
			sentAt: now,
			isMine: true,
		);

		_topics.insert(0, topic);
		_messagesByTopic[topicId] = [message];
		notifyListeners();
		return topic;
	}

	CommunityMessage? sendMessage({
		required String topicId,
		required String text,
	}) {
		final trimmedText = text.trim();
		if (trimmedText.isEmpty) {
			return null;
		}

		final topicIndex = _topics.indexWhere((topic) => topic.id == topicId);
		if (topicIndex < 0) {
			return null;
		}

		final now = DateTime.now();
		final messageId = 'm-$_nextMessageId';
		_nextMessageId += 1;

		final message = CommunityMessage(
			id: messageId,
			topicId: topicId,
			authorName: DemoCommunityData.currentUserName,
			text: trimmedText,
			sentAt: now,
			isMine: true,
		);

		final messages = _messagesByTopic.putIfAbsent(topicId, () => []);
		messages.add(message);

		final topic = _topics[topicIndex];
		_topics[topicIndex] = topic.copyWith(
			lastMessage: trimmedText,
			lastMessageAt: now,
			unreadCount: 0,
		);

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
