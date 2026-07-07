class CommunityMessage {
	const CommunityMessage({
		required this.id,
		required this.topicId,
		required this.authorName,
		required this.text,
		required this.sentAt,
		this.isMine = false,
	});

	final String id;
	final String topicId;
	final String authorName;
	final String text;
	final DateTime sentAt;
	final bool isMine;
}
