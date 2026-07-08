class CommunityMessage {
	const CommunityMessage({
		required this.id,
		required this.topicId,
		required this.authorName,
		required this.text,
		required this.sentAt,
		this.isMine = false,
		this.attachmentUrl,
		this.attachmentName,
	});

	final String id;
	final String topicId;
	final String authorName;
	final String text;
	final DateTime sentAt;
	final bool isMine;
	final String? attachmentUrl;
	final String? attachmentName;
}
