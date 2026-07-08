import '../models/master_service.dart';
import '../services/api/app_api_repository.dart';
import '../services/api/beauty_trust_api.dart';

class MasterServicesData {
	MasterServicesData._();

	static final AppApiRepository _api = AppApiRepository();
	static List<MasterService> _cache = [];

	static List<MasterService> get services => List<MasterService>.from(_cache);

	static Future<List<MasterService>> load({bool force = false}) async {
		if (!force && _cache.isNotEmpty) {
			return services;
		}

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

	static Future<MasterService> create({
		required String name,
		required String durationLabel,
		required int price,
	}) async {
		final created = await _api.createMasterService(
			name: name,
			durationLabel: durationLabel,
			price: price,
		);
		_cache = [..._cache, created];
		return created;
	}

	static Future<MasterService> update({
		required int serviceId,
		required String name,
		required String durationLabel,
		required int price,
	}) async {
		final updated = await _api.updateMasterService(
			serviceId: serviceId,
			name: name,
			durationLabel: durationLabel,
			price: price,
		);
		final index = _cache.indexWhere((item) => item.id == serviceId);
		if (index == -1) {
			_cache = [..._cache, updated];
		} else {
			_cache = [..._cache]..[index] = updated;
		}
		return updated;
	}

	static Future<void> delete(int serviceId) async {
		await _api.deleteMasterService(serviceId);
		_cache = _cache.where((item) => item.id != serviceId).toList();
	}

	static MasterService? findByName(String name) {
		for (final service in _cache) {
			if (service.name == name) {
				return service;
			}
		}
		return null;
	}

	static void clearCache() {
		_cache = [];
	}
}
