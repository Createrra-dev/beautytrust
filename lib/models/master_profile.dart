class MasterProfile {
	const MasterProfile({
		required this.firstName,
		required this.badgeLabel,
		required this.rating,
		required this.reviewsCount,
		required this.clientsCount,
		required this.preventedNoShows,
		required this.protectedIncome,
		required this.tariffLabel,
	});

	final String firstName;
	final String badgeLabel;
	final double rating;
	final int reviewsCount;
	final int clientsCount;
	final int preventedNoShows;
	final int protectedIncome;
	final String tariffLabel;
}

enum MasterProfileMenuItem {
	statistics,
	reviews,
	tariff,
	settings,
	support,
	logout,
}

extension MasterProfileMenuItemX on MasterProfileMenuItem {
	String get title {
		return switch (this) {
			MasterProfileMenuItem.statistics => 'Статистика',
			MasterProfileMenuItem.reviews => 'Отзывы',
			MasterProfileMenuItem.tariff => 'Тариф',
			MasterProfileMenuItem.settings => 'Настройки',
			MasterProfileMenuItem.support => 'Поддержка',
			MasterProfileMenuItem.logout => 'Выйти',
		};
	}
}
