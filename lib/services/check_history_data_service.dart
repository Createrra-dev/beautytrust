import '../models/check_history_record.dart';
import 'api/app_api_repository.dart';

class CheckHistoryDataService {
	CheckHistoryDataService._();

	static final AppApiRepository _api = AppApiRepository();

	static Future<List<CheckHistoryRecord>> checksFor(CheckHistoryFilter filter) {
		return _api.fetchCheckHistory(filter: filter);
	}
}
