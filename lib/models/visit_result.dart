enum VisitPunctuality {
	onTime,
	late,
	noShow,
}

class VisitResult {
	const VisitResult({
		required this.punctuality,
		required this.paidInFull,
		required this.hadBehaviorIssues,
		required this.wasUnfriendly,
		required this.hadScandal,
		required this.threatenedComplaints,
		required this.demandedDiscount,
		required this.stoleFromSalon,
		required this.leftTips,
		this.comment,
	});

	final VisitPunctuality punctuality;
	final bool paidInFull;
	final bool hadBehaviorIssues;
	final bool wasUnfriendly;
	final bool hadScandal;
	final bool threatenedComplaints;
	final bool demandedDiscount;
	final bool stoleFromSalon;
	final bool leftTips;
	final String? comment;

	bool get clientAttended {
		return punctuality != VisitPunctuality.noShow;
	}

	static VisitResult defaults() {
		return const VisitResult(
			punctuality: VisitPunctuality.onTime,
			paidInFull: true,
			hadBehaviorIssues: false,
			wasUnfriendly: false,
			hadScandal: false,
			threatenedComplaints: false,
			demandedDiscount: false,
			stoleFromSalon: false,
			leftTips: false,
		);
	}
}

double? calculateVisitResultRating({
	VisitPunctuality? punctuality,
	bool? paidInFull,
	bool? hadBehaviorIssues,
	bool? wasUnfriendly,
	bool? hadScandal,
	bool? threatenedComplaints,
	bool? demandedDiscount,
	bool? stoleFromSalon,
	bool? leftTips,
}) {
	if (punctuality == null) {
		return null;
	}

	if (punctuality == VisitPunctuality.noShow) {
		return 1.5;
	}

	if (paidInFull == null || hadBehaviorIssues == null || leftTips == null) {
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

	if (hadBehaviorIssues) {
		score -= 0.8;
		if (wasUnfriendly == true) {
			score -= 0.3;
		}
		if (hadScandal == true) {
			score -= 0.8;
		}
		if (threatenedComplaints == true) {
			score -= 1.0;
		}
		if (demandedDiscount == true) {
			score -= 0.5;
		}
		if (stoleFromSalon == true) {
			score -= 1.5;
		}
	}

	if (leftTips) {
		score += 0.2;
	}

	return double.parse(score.clamp(1.0, 5.0).toStringAsFixed(1));
}
