class MasterReview {
	const MasterReview({
		required this.masterName,
		required this.rating,
		required this.text,
		required this.tag,
	});

	final String masterName;
	final int rating;
	final String text;
	final String tag;
}

class ClientProfile {
	const ClientProfile({
		required this.phone,
		required this.ratingLabel,
		required this.reviewsAverage,
		required this.reviewsCount,
		required this.noShowsCount,
		required this.scandalsCount,
		required this.reviews,
		required this.reliabilityTitle,
		required this.reliabilitySubtitle,
	});

	final String phone;
	final String ratingLabel;
	final double reviewsAverage;
	final int reviewsCount;
	final int noShowsCount;
	final int scandalsCount;
	final List<MasterReview> reviews;
	final String reliabilityTitle;
	final String reliabilitySubtitle;
}
