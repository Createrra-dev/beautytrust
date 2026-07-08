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

	factory TariffPlan.fromJson(Map<String, dynamic> json) {
		final audienceRaw = json['audience'] as String? ?? 'masters';
		return TariffPlan(
			id: json['id'] as String,
			title: json['title'] as String,
			monthlyPrice: json['monthly_price'] as int,
			trialLabel: json['trial_label'] as String? ?? '',
			features: (json['features'] as List<dynamic>? ?? const [])
				.map((item) => item.toString())
				.toList(),
			cardButtonLabel: json['card_button_label'] as String? ?? 'Выбрать тариф',
			audience: audienceRaw == 'studios'
				? TariffAudience.studios
				: TariffAudience.masters,
			isPopular: json['is_popular'] as bool? ?? false,
		);
	}

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

class MasterSubscription {
	const MasterSubscription({
		required this.planId,
		required this.planTitle,
		required this.tariffLabel,
		required this.isActive,
		this.expiresAt,
		this.monthlyPrice = 0,
	});

	final String planId;
	final String planTitle;
	final String tariffLabel;
	final bool isActive;
	final DateTime? expiresAt;
	final int monthlyPrice;

	factory MasterSubscription.fromJson(Map<String, dynamic> json) {
		final expiresRaw = json['expires_at'] as String?;
		return MasterSubscription(
			planId: json['plan_id'] as String,
			planTitle: json['plan_title'] as String,
			tariffLabel: json['tariff_label'] as String,
			isActive: json['is_active'] as bool? ?? false,
			expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw)?.toLocal(),
			monthlyPrice: json['monthly_price'] as int? ?? 0,
		);
	}
}

class SubscribeResult {
	const SubscribeResult({
		required this.amount,
		required this.months,
		required this.planId,
		required this.activated,
		this.paymentId,
		this.paymentUrl,
		this.orderId,
		this.subscription,
	});

	final String? paymentId;
	final String? paymentUrl;
	final String? orderId;
	final int amount;
	final int months;
	final String planId;
	final bool activated;
	final MasterSubscription? subscription;

	factory SubscribeResult.fromJson(Map<String, dynamic> json) {
		final subscriptionJson = json['subscription'] as Map<String, dynamic>?;
		return SubscribeResult(
			paymentId: json['payment_id'] as String?,
			paymentUrl: json['payment_url'] as String?,
			orderId: json['order_id'] as String?,
			amount: json['amount'] as int,
			months: json['months'] as int,
			planId: json['plan_id'] as String,
			activated: json['activated'] as bool? ?? false,
			subscription: subscriptionJson == null
				? null
				: MasterSubscription.fromJson(subscriptionJson),
		);
	}
}
