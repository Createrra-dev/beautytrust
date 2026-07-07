import '../models/tariff_plan.dart';

class TariffPaymentSummary {
	const TariffPaymentSummary({
		required this.plan,
		required this.months,
		required this.totalRubles,
		required this.baseTotalRubles,
		required this.discountPercent,
		required this.savedRubles,
	});

	final TariffPlan plan;
	final int months;
	final int totalRubles;
	final int baseTotalRubles;
	final int discountPercent;
	final int savedRubles;

	int get amountKopecks => totalRubles * 100;

	String get description =>
		'Подписка «${plan.title}» на $months мес.';
}

class TariffSubscriptionPeriod {
	const TariffSubscriptionPeriod({
		required this.months,
		required this.label,
	});

	final int months;
	final String label;

	static const List<TariffSubscriptionPeriod> options = [
		TariffSubscriptionPeriod(months: 1, label: '1 месяц'),
		TariffSubscriptionPeriod(months: 3, label: '3 месяца'),
		TariffSubscriptionPeriod(months: 6, label: '6 месяцев'),
		TariffSubscriptionPeriod(months: 9, label: '9 месяцев'),
		TariffSubscriptionPeriod(months: 12, label: '1 год'),
	];
}
