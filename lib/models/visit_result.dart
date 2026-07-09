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

double? calculateVisitResultRating({
	VisitPunctuality? punctuality,
	bool? paidInFull,
	bool? hadScandal,
	bool? leftTips,
}) {
	if (punctuality == null) {
		return null;
	}

	if (punctuality == VisitPunctuality.noShow) {
		return 1.5;
	}

	if (paidInFull == null || hadScandal == null || leftTips == null) {
		return null;
	}

	var score = 4.0;
	if (punctuality == VisitPunctuality.onTime) {
		score += 0.5;
	} else if (punctuality == VisitPunctuality.late) {
		score -= 0.5;
	}

	if (paidInFull) {
		score += 0.3;
	} else {
		score -= 1.0;
	}

	if (hadScandal) {
		score -= 2.0;
	}

	if (leftTips) {
		score += 0.2;
	}

	return double.parse(score.clamp(1.0, 5.0).toStringAsFixed(1));
}
