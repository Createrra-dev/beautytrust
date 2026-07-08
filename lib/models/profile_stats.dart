class ProfileStats {
	const ProfileStats({
		required this.appointmentsTotal,
		required this.appointmentsScheduled,
		required this.appointmentsCompleted,
		required this.appointmentsNoShow,
		required this.appointmentsCancelled,
		required this.completionRate,
		required this.avgClientRating,
		required this.checksTotal,
		required this.reviewsGiven,
	});

	final int appointmentsTotal;
	final int appointmentsScheduled;
	final int appointmentsCompleted;
	final int appointmentsNoShow;
	final int appointmentsCancelled;
	final double completionRate;
	final double avgClientRating;
	final int checksTotal;
	final int reviewsGiven;
}
