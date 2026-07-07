enum VisitPunctuality {
	onTime,
	late,
	noShow,
}

class VisitResult {
	const VisitResult({
		required this.punctuality,
		required this.paidInFull,
		required this.hadScandal,
		required this.leftTips,
		this.comment,
	});

	final VisitPunctuality punctuality;
	final bool paidInFull;
	final bool hadScandal;
	final bool leftTips;
	final String? comment;

	bool get clientAttended {
		return punctuality != VisitPunctuality.noShow;
	}
}
