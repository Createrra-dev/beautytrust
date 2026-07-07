class DashboardPeriod {
	const DashboardPeriod({
		required this.year,
		required this.month,
	});

	final int year;
	final int month;

	String get label {
		return '${_monthNames[month - 1]} $year';
	}

	String get previousMonthLabel {
		final previousMonth = month == 1 ? 12 : month - 1;
		return _monthNames[previousMonth - 1];
	}

	static const _monthNames = [
		'Январь',
		'Февраль',
		'Март',
		'Апрель',
		'Май',
		'Июнь',
		'Июль',
		'Август',
		'Сентябрь',
		'Октябрь',
		'Ноябрь',
		'Декабрь',
	];
}
