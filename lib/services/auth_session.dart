import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
	AuthSession._();

	static const _tokenKey = 'auth_access_token';
	static const _masterIdKey = 'auth_master_id';
	static const _pinKey = 'auth_pin_code';
	static const _pinPhoneKey = 'auth_pin_phone';
	static const _pinSetAtKey = 'auth_pin_set_at';
	static const _biometricEnabledKey = 'auth_biometric_enabled';

	static String? pinCode;
	static String? pinPhoneDigits;
	static int? pinSetAtMs;
	static bool biometricEnabled = false;
	static String? accessToken;
	static int? masterId;

	static Future<void> load() async {
		final preferences = await SharedPreferences.getInstance();
		accessToken = preferences.getString(_tokenKey);
		masterId = preferences.getInt(_masterIdKey);
		pinCode = preferences.getString(_pinKey);
		pinPhoneDigits = preferences.getString(_pinPhoneKey);
		pinSetAtMs = preferences.getInt(_pinSetAtKey);
		biometricEnabled = preferences.getBool(_biometricEnabledKey) ?? false;
	}

	static bool get hasStoredPin =>
		pinCode != null &&
		pinCode!.isNotEmpty &&
		pinPhoneDigits != null &&
		pinPhoneDigits!.length == 10;

	static Future<bool> hasStoredPinForPhone(String phoneDigits) async {
		await load();
		return pinPhoneDigits == phoneDigits && hasStoredPin;
	}

	static Future<void> savePin({
		required String pin,
		required String phoneDigits,
	}) async {
		pinCode = pin;
		pinPhoneDigits = phoneDigits;
		pinSetAtMs = DateTime.now().millisecondsSinceEpoch;

		final preferences = await SharedPreferences.getInstance();
		await preferences.setString(_pinKey, pin);
		await preferences.setString(_pinPhoneKey, phoneDigits);
		await preferences.setInt(_pinSetAtKey, pinSetAtMs!);
	}

	static Future<void> setBiometricEnabled(bool enabled) async {
		biometricEnabled = enabled;
		final preferences = await SharedPreferences.getInstance();
		if (enabled) {
			await preferences.setBool(_biometricEnabledKey, true);
			return;
		}

		await preferences.remove(_biometricEnabledKey);
	}

	static Future<void> clearPin() async {
		pinCode = null;
		pinPhoneDigits = null;
		pinSetAtMs = null;
		biometricEnabled = false;

		final preferences = await SharedPreferences.getInstance();
		await preferences.remove(_pinKey);
		await preferences.remove(_pinPhoneKey);
		await preferences.remove(_pinSetAtKey);
		await preferences.remove(_biometricEnabledKey);
	}

	static Future<void> clearAll() async {
		await clearPin();
		await clearAuth();
	}

	static Future<void> saveAuth({
		required String token,
		required int savedMasterId,
	}) async {
		accessToken = token;
		masterId = savedMasterId;
		final preferences = await SharedPreferences.getInstance();
		await preferences.setString(_tokenKey, token);
		await preferences.setInt(_masterIdKey, savedMasterId);
	}

	static Future<void> clearAuth() async {
		accessToken = null;
		masterId = null;
		final preferences = await SharedPreferences.getInstance();
		await preferences.remove(_tokenKey);
		await preferences.remove(_masterIdKey);
	}

	static bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
}
