class CommunityTopic {
	const CommunityTopic({
		required this.id,
		required this.title,
		required this.authorName,
		required this.createdAt,
		required this.participantCount,
		required this.lastMessage,
		required this.lastMessageAt,
		required this.participantInitials,
		this.unreadCount = 0,
		this.isPinned = false,
		this.isClosed = false,
		this.emoji = '💬',
	});

	final String id;
	final String title;
	final String authorName;
	final DateTime createdAt;
	final int participantCount;
	final String lastMessage;
	final DateTime lastMessageAt;
	final List<String> participantInitials;
	final int unreadCount;
	final bool isPinned;
	final bool isClosed;
	final String emoji;

	CommunityTopic copyWith({
		String? lastMessage,
		DateTime? lastMessageAt,
		int? participantCount,
		int? unreadCount,
		List<String>? participantInitials,
		bool? isClosed,
	}) {
		return CommunityTopic(
			id: id,
			title: title,
			authorName: authorName,
			createdAt: createdAt,
			participantCount: participantCount ?? this.participantCount,
			lastMessage: lastMessage ?? this.lastMessage,
			lastMessageAt: lastMessageAt ?? this.lastMessageAt,
			participantInitials: participantInitials ?? this.participantInitials,
			unreadCount: unreadCount ?? this.unreadCount,
			isPinned: isPinned,
			isClosed: isClosed ?? this.isClosed,
			emoji: emoji,
		);
	}
}

String formatCommunityTime(DateTime dateTime, {DateTime? referenceNow}) {
	final now = referenceNow ?? DateTime.now();
	final timeLabel =
		'${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

	if (_isSameDay(dateTime, now)) {
		return timeLabel;
	}

	final yesterday = DateTime(now.year, now.month, now.day - 1);
	if (_isSameDay(dateTime, yesterday)) {
		return 'Вчера';
	}

	return '${dateTime.day.toString().padLeft(2, '0')}.'
		'${dateTime.month.toString().padLeft(2, '0')}';
}

bool _isSameDay(DateTime left, DateTime right) {
	return left.year == right.year &&
		left.month == right.month &&
		left.day == right.day;
}
