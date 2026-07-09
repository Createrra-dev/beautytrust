class MasterSettings {
	const MasterSettings({
		required this.pushNotificationsEnabled,
		required this.emailNotificationsEnabled,
		required this.marketingNotificationsEnabled,
		required this.visitResultDefaultsEnabled,
	});

	final bool pushNotificationsEnabled;
	final bool emailNotificationsEnabled;
	final bool marketingNotificationsEnabled;
	final bool visitResultDefaultsEnabled;

	MasterSettings copyWith({
		bool? pushNotificationsEnabled,
		bool? emailNotificationsEnabled,
		bool? marketingNotificationsEnabled,
		bool? visitResultDefaultsEnabled,
	}) {
		return MasterSettings(
			pushNotificationsEnabled:
				pushNotificationsEnabled ?? this.pushNotificationsEnabled,
			emailNotificationsEnabled:
				emailNotificationsEnabled ?? this.emailNotificationsEnabled,
			marketingNotificationsEnabled:
				marketingNotificationsEnabled ?? this.marketingNotificationsEnabled,
			visitResultDefaultsEnabled:
				visitResultDefaultsEnabled ?? this.visitResultDefaultsEnabled,
		);
	}
}
