enum AppointmentStatus {
	confirmed,
	pendingVerification,
	atRisk,
}

class AppointmentRecord {
	const AppointmentRecord({
		required this.clientName,
		required this.serviceName,
		required this.timeLabel,
		required this.dateLabel,
		required this.status,
	});

	final String clientName;
	final String serviceName;
	final String timeLabel;
	final String dateLabel;
	final AppointmentStatus status;

	String get statusLabel {
		return switch (status) {
			AppointmentStatus.confirmed => 'Подтверждена',
			AppointmentStatus.pendingVerification => 'Ожидает проверки',
			AppointmentStatus.atRisk => 'Риск неявки',
		};
	}
}
