enum TariffAudience {
	masters,
	studios,
}

class TariffPlan {
	const TariffPlan({
		required this.id,
		required this.title,
		required this.monthlyPrice,
		required this.trialLabel,
		required this.features,
		required this.cardButtonLabel,
		required this.audience,
		this.isPopular = false,
	});

	final String id;
	final String title;
	final int monthlyPrice;
	final String trialLabel;
	final List<String> features;
	final String cardButtonLabel;
	final TariffAudience audience;
	final bool isPopular;

	String get priceLabel {
		if (monthlyPrice == 0) {
			return '0 ₽ / мес.';
		}

		return '$monthlyPrice ₽ / мес.';
	}

	String get detailSubtitle {
		if (monthlyPrice == 0) {
			return trialLabel;
		}

		return '$trialLabel, далее $monthlyPrice ₽ / мес.';
	}
}
