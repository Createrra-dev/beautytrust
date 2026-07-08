class AppNotification {
	const AppNotification({
		required this.id,
		required this.title,
		required this.body,
		required this.kind,
		required this.isRead,
		required this.createdAt,
		this.payload,
	});

	final int id;
	final String title;
	final String body;
	final String kind;
	final bool isRead;
	final DateTime createdAt;
	final Map<String, dynamic>? payload;

	factory AppNotification.fromJson(Map<String, dynamic> json) {
		return AppNotification(
			id: json['id'] as int,
			title: json['title'] as String,
			body: json['body'] as String,
			kind: json['kind'] as String? ?? 'general',
			isRead: json['is_read'] as bool? ?? false,
			createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
			payload: json['payload'] as Map<String, dynamic>?,
		);
	}
}
