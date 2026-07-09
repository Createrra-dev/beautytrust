class YClientsIntegration {
	const YClientsIntegration({
		required this.enabled,
		required this.partnerToken,
		required this.companyId,
		required this.login,
		required this.hasUserToken,
		required this.authPending,
		required this.authRecipient,
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
	final DateTime? lastSyncAt;
	final int lastSyncCount;

	YClientsIntegration copyWith({
		bool? enabled,
		String? partnerToken,
		String? companyId,
		String? login,
		bool? hasUserToken,
		bool? authPending,
		String? authRecipient,
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
