class DashboardStats {
	const DashboardStats({
		required this.periodLabel,
		required this.protectedIncome,
		required this.incomeTrendLabel,
		required this.incomeTrendPositive,
		required this.sparklineValues,
		required this.preventedNoShows,
		required this.noShowsTrendLabel,
		required this.completedChecks,
		required this.checksTrendLabel,
	});

	final String periodLabel;
	final int protectedIncome;
	final String incomeTrendLabel;
	final bool incomeTrendPositive;
	final List<double> sparklineValues;
	final int preventedNoShows;
	final String noShowsTrendLabel;
	final int completedChecks;
	final String checksTrendLabel;

	static const mock = DashboardStats(
		periodLabel: 'Март 2024',
		protectedIncome: 156000,
		incomeTrendLabel: '+23% к февралю',
		incomeTrendPositive: true,
		sparklineValues: [0.35, 0.42, 0.38, 0.55, 0.48, 0.62, 0.58, 0.72, 0.68, 0.85, 0.78, 1.0],
		preventedNoShows: 12,
		noShowsTrendLabel: '-3 к февралю',
		completedChecks: 247,
		checksTrendLabel: '+31 к февралю',
	);
}

String formatRubles(int amount) {
	final text = amount.toString();
	final buffer = StringBuffer();

	for (var index = 0; index < text.length; index++) {
		final positionFromEnd = text.length - index;
		if (index > 0 && positionFromEnd % 3 == 0) {
			buffer.write(' ');
		}
		buffer.write(text[index]);
	}

	return '${buffer.toString()} ₽';
}
