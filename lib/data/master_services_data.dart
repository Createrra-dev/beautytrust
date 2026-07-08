import '../models/master_service.dart';
import '../services/api/app_api_repository.dart';
import '../services/api/beauty_trust_api.dart';

class MasterServicesData {
	MasterServicesData._();

	static final AppApiRepository _api = AppApiRepository();
	static List<MasterService> _cache = [];

	static List<MasterService> get services => List<MasterService>.from(_cache);

	static Future<List<MasterService>> load() async {
		try {
			_cache = await _api.fetchMasterServices();
		} on ApiException {
			if (_cache.isEmpty) {
				_cache = const [
					MasterService(
						name: 'Маникюр + покрытие',
						durationLabel: '2 ч',
						price: 2500,
					),
				];
			}
		}
		return services;
	}

	static MasterService? findByName(String name) {
		for (final service in _cache) {
			if (service.name == name) {
				return service;
			}
		}
		return null;
	}
}
