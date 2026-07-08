import 'package:local_auth/local_auth.dart';

enum BiometricUnlockResult {
	success,
	cancelled,
	unavailable,
	failed,
}

class BiometricAuthService {
	BiometricAuthService({LocalAuthentication? localAuth})
		: _localAuth = localAuth ?? LocalAuthentication();

	final LocalAuthentication _localAuth;

	Future<bool> get canAuthenticate async {
		try {
			final isSupported = await _localAuth.isDeviceSupported();
			if (!isSupported) {
				return false;
			}

			final canCheckBiometrics = await _localAuth.canCheckBiometrics;
			final availableBiometrics = await _localAuth.getAvailableBiometrics();
			return canCheckBiometrics && availableBiometrics.isNotEmpty;
		} on LocalAuthException {
			return false;
		}
	}

	Future<String> biometricLabel() async {
		final biometrics = await _localAuth.getAvailableBiometrics();
		if (biometrics.contains(BiometricType.face)) {
			return 'Face ID';
		}

		if (biometrics.contains(BiometricType.strong) ||
			biometrics.contains(BiometricType.fingerprint)) {
			return 'отпечатку пальца';
		}

		return 'биометрии';
	}

	Future<BiometricUnlockResult> authenticate({
		required String reason,
	}) async {
		if (!await canAuthenticate) {
			return BiometricUnlockResult.unavailable;
		}

		try {
			final authenticated = await _localAuth.authenticate(
				localizedReason: reason,
				biometricOnly: true,
				persistAcrossBackgrounding: true,
			);
			return authenticated
				? BiometricUnlockResult.success
				: BiometricUnlockResult.cancelled;
		} on LocalAuthException catch (error) {
			if (error.code == LocalAuthExceptionCode.userCanceled ||
				error.code == LocalAuthExceptionCode.systemCanceled) {
				return BiometricUnlockResult.cancelled;
			}

			if (error.code == LocalAuthExceptionCode.noBiometricHardware ||
				error.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
				return BiometricUnlockResult.unavailable;
			}

			return BiometricUnlockResult.failed;
		}
	}
}
