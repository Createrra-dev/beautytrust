class YClientsIntegration {
	const YClientsIntegration({
		required this.enabled,
		required this.partnerToken,
		required this.companyId,
		required this.login,
		required this.hasUserToken,
		required this.authPending,
		required this.authRecipient,
		required this.syncIntervalMinutes,
		this.lastSyncAt,
		required this.lastSyncCount,
	});

	final bool enabled;
	final String partnerToken;
	final String companyId;
	final String login;
	final bool hasUserToken;
	final bool authPending;
	final String authRecipient;
	final int syncIntervalMinutes;
	final DateTime? lastSyncAt;
	final int lastSyncCount;

	static const syncIntervalOptions = <({int minutes, String label})>[
		(minutes: 0, label: 'Только вручную'),
		(minutes: 5, label: 'Каждые 5 минут'),
		(minutes: 15, label: 'Каждые 15 минут'),
		(minutes: 30, label: 'Каждые 30 минут'),
		(minutes: 60, label: 'Каждый час'),
		(minutes: 180, label: 'Каждые 3 часа'),
	];

	static String syncIntervalLabel(int minutes) {
		for (final option in syncIntervalOptions) {
			if (option.minutes == minutes) {
				return option.label;
			}
		}
		return 'Каждые 15 минут';
	}

	YClientsIntegration copyWith({
		bool? enabled,
		String? partnerToken,
		String? companyId,
		String? login,
		bool? hasUserToken,
		bool? authPending,
		String? authRecipient,
		int? syncIntervalMinutes,
		DateTime? lastSyncAt,
		int? lastSyncCount,
	}) {
		return YClientsIntegration(
			enabled: enabled ?? this.enabled,
			partnerToken: partnerToken ?? this.partnerToken,
			companyId: companyId ?? this.companyId,
			login: login ?? this.login,
			hasUserToken: hasUserToken ?? this.hasUserToken,
			authPending: authPending ?? this.authPending,
			authRecipient: authRecipient ?? this.authRecipient,
			syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
			lastSyncAt: lastSyncAt ?? this.lastSyncAt,
			lastSyncCount: lastSyncCount ?? this.lastSyncCount,
		);
	}
}

class YClientsSyncResult {
	const YClientsSyncResult({
		required this.imported,
		required this.updated,
		required this.skipped,
	});

	final int imported;
	final int updated;
	final int skipped;
}
