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
		this.email,
		this.phoneDigits,
		this.avatarUrl,
		this.yearsExperience = 0,
	});

	final String firstName;
	final String badgeLabel;
	final double rating;
	final int reviewsCount;
	final int clientsCount;
	final int preventedNoShows;
	final int protectedIncome;
	final String tariffLabel;
	final String? email;
	final String? phoneDigits;
	final String? avatarUrl;
	final int yearsExperience;

	MasterProfile copyWith({
		String? firstName,
		String? badgeLabel,
		double? rating,
		int? reviewsCount,
		int? clientsCount,
		int? preventedNoShows,
		int? protectedIncome,
		String? tariffLabel,
		String? email,
		String? phoneDigits,
		String? avatarUrl,
		int? yearsExperience,
		bool clearEmail = false,
		bool clearAvatarUrl = false,
	}) {
		return MasterProfile(
			firstName: firstName ?? this.firstName,
			badgeLabel: badgeLabel ?? this.badgeLabel,
			rating: rating ?? this.rating,
			reviewsCount: reviewsCount ?? this.reviewsCount,
			clientsCount: clientsCount ?? this.clientsCount,
			preventedNoShows: preventedNoShows ?? this.preventedNoShows,
			protectedIncome: protectedIncome ?? this.protectedIncome,
			tariffLabel: tariffLabel ?? this.tariffLabel,
			email: clearEmail ? null : (email ?? this.email),
			phoneDigits: phoneDigits ?? this.phoneDigits,
			avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
			yearsExperience: yearsExperience ?? this.yearsExperience,
		);
	}
}

enum MasterProfileMenuItem {
	services,
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
			MasterProfileMenuItem.services => 'Услуги',
			MasterProfileMenuItem.statistics => 'Статистика',
			MasterProfileMenuItem.reviews => 'Отзывы',
			MasterProfileMenuItem.tariff => 'Тариф',
			MasterProfileMenuItem.settings => 'Настройки',
			MasterProfileMenuItem.support => 'Поддержка',
			MasterProfileMenuItem.logout => 'Выйти',
		};
	}
}
