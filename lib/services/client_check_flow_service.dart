import 'package:flutter/foundation.dart';

import '../navigation/main_shell_navigation.dart';

class ClientCheckFlowService extends ChangeNotifier {
	ClientCheckFlowService._();

	static final ClientCheckFlowService instance = ClientCheckFlowService._();

	String? _pendingPhone;

	void checkPhoneFromHome(String phone) {
		_pendingPhone = phone;
		MainShellNavigation.instance.goToCheck();
		notifyListeners();
	}

	String? consumePendingPhone() {
		final phone = _pendingPhone;
		_pendingPhone = null;
		return phone;
	}
}
