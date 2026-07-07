import '../models/tariff_payment_summary.dart';
import '../models/tariff_plan.dart';

class TariffPriceQuote {
	const TariffPriceQuote({
		required this.months,
		required this.baseTotalRubles,
		required this.discountPercent,
		required this.savedRubles,
		required this.totalRubles,
	});

	final int months;
	final int baseTotalRubles;
	final int discountPercent;
	final int savedRubles;
	final int totalRubles;
}

class TariffPricingService {
	TariffPricingService._();

	static const maxDiscountPercent = 30;
	static const maxDiscountMonths = 12;

	static TariffPriceQuote quote({
		required int monthlyPriceRubles,
		required int months,
	}) {
		final baseTotalRubles = monthlyPriceRubles * months;
		final discountPercent = discountPercentForMonths(months);
		final totalRubles =
			(baseTotalRubles * (100 - discountPercent) / 100).round();
		final savedRubles = baseTotalRubles - totalRubles;

		return TariffPriceQuote(
			months: months,
			baseTotalRubles: baseTotalRubles,
			discountPercent: discountPercent,
			savedRubles: savedRubles,
			totalRubles: totalRubles,
		);
	}

	static TariffPaymentSummary buildSummary({
		required TariffPlan plan,
		required int months,
	}) {
		final priceQuote = quote(
			monthlyPriceRubles: plan.monthlyPrice,
			months: months,
		);

		return TariffPaymentSummary(
			plan: plan,
			months: months,
			totalRubles: priceQuote.totalRubles,
			baseTotalRubles: priceQuote.baseTotalRubles,
			discountPercent: priceQuote.discountPercent,
			savedRubles: priceQuote.savedRubles,
		);
	}

	static int discountPercentForMonths(int months) {
		if (months <= 1) {
			return 0;
		}

		if (months >= maxDiscountMonths) {
			return maxDiscountPercent;
		}

		final progress = (months - 1) / (maxDiscountMonths - 1);
		return (maxDiscountPercent * progress).round();
	}
}
