class MasterSettings {
	const MasterSettings({
		required this.pushNotificationsEnabled,
		required this.emailNotificationsEnabled,
		required this.marketingNotificationsEnabled,
	});

	final bool pushNotificationsEnabled;
	final bool emailNotificationsEnabled;
	final bool marketingNotificationsEnabled;

	MasterSettings copyWith({
		bool? pushNotificationsEnabled,
		bool? emailNotificationsEnabled,
		bool? marketingNotificationsEnabled,
	}) {
		return MasterSettings(
			pushNotificationsEnabled:
				pushNotificationsEnabled ?? this.pushNotificationsEnabled,
			emailNotificationsEnabled:
				emailNotificationsEnabled ?? this.emailNotificationsEnabled,
			marketingNotificationsEnabled:
				marketingNotificationsEnabled ?? this.marketingNotificationsEnabled,
		);
	}
}
