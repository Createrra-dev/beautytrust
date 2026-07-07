import '../models/master_profile.dart';

class MasterProfileService {
	MasterProfileService._();

	static const MasterProfile currentMaster = MasterProfile(
		firstName: 'Анна',
		badgeLabel: 'Премиум мастер',
		rating: 4.8,
		reviewsCount: 128,
		clientsCount: 247,
		preventedNoShows: 12,
		protectedIncome: 156000,
		tariffLabel: 'Мастер',
	);
}
