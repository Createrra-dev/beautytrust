import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/code_dots.dart';
import '../../widgets/auth/numeric_keypad.dart';
import '../../services/auth_session.dart';
import '../../services/biometric_auth_service.dart';
import '../home/main_shell_screen.dart';

enum PinCodeMode {
	setup,
	confirm,
	entry,
}

class PinCodeScreen extends StatefulWidget {
	const PinCodeScreen({
		super.key,
		required this.mode,
		this.initialPin,
		this.phoneDigits,
		this.tryBiometricOnOpen = false,
	});

	final PinCodeMode mode;
	final String? initialPin;
	final String? phoneDigits;
	final bool tryBiometricOnOpen;

	@override
	State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
	static const _pinLength = 4;

	final _biometricAuthService = BiometricAuthService();

	late PinCodeMode _mode;
	final _digits = <String>[];
	String? _firstPin;
	String? _errorMessage;
	var _biometricAvailable = false;
	var _biometricLabel = 'Face ID';
	var _isBiometricUnlocking = false;

	@override
	void initState() {
		super.initState();
		_mode = widget.mode;
		_firstPin = widget.initialPin;
		_initializeEntryMode();
	}

	Future<void> _initializeEntryMode() async {
		if (_mode != PinCodeMode.entry) {
			return;
		}

		await _loadBiometricState();
		await _validatePinSession();

		if (!widget.tryBiometricOnOpen || !AuthSession.biometricEnabled) {
			return;
		}

		await _tryBiometricUnlock();
	}

	Future<void> _loadBiometricState() async {
		final canAuthenticate = await _biometricAuthService.canAuthenticate;
		final label = await _biometricAuthService.biometricLabel();
		if (!mounted) {
			return;
		}

		setState(() {
			_biometricAvailable = canAuthenticate;
			_biometricLabel = label;
		});
	}

	Future<void> _validatePinSession() async {
		if (_mode != PinCodeMode.entry) {
			return;
		}

		final phoneDigits = widget.phoneDigits;
		if (phoneDigits == null) {
			return;
		}

		final hasValidPin = await AuthSession.hasStoredPinForPhone(phoneDigits);
		if (!hasValidPin && mounted) {
			setState(() {
				_errorMessage = 'PIN не найден. Войдите по коду из Telegram.';
			});
		}
	}

	Future<void> _tryBiometricUnlock() async {
		if (!AuthSession.biometricEnabled || !_biometricAvailable || _isBiometricUnlocking) {
			return;
		}

		setState(() {
			_isBiometricUnlocking = true;
			_errorMessage = null;
		});

		final result = await _biometricAuthService.authenticate(
			reason: 'Войдите в Beauty Trust',
		);

		if (!mounted) {
			return;
		}

		setState(() => _isBiometricUnlocking = false);

		if (result == BiometricUnlockResult.success) {
			_openHome();
			return;
		}

		if (result == BiometricUnlockResult.failed) {
			setState(() {
				_errorMessage = 'Не удалось войти по $_biometricLabel. Введите PIN.';
			});
		}
	}

	Future<void> _offerBiometricSetup() async {
		if (!await _biometricAuthService.canAuthenticate || !mounted) {
			_openHome();
			return;
		}

		final label = await _biometricAuthService.biometricLabel();
		if (!mounted) {
			return;
		}

		final shouldEnable = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: Text('Включить вход по $label?'),
					content: Text(
						'При следующем запуске приложения можно будет входить по $label без ввода PIN.',
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Не сейчас'),
						),
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							child: const Text('Включить'),
						),
					],
				);
			},
		);

		if (shouldEnable == true) {
			final result = await _biometricAuthService.authenticate(
				reason: 'Подтвердите включение входа по $label',
			);
			if (result == BiometricUnlockResult.success) {
				await AuthSession.setBiometricEnabled(true);
			}
		}

		if (!mounted) {
			return;
		}

		_openHome();
	}

	String get _title {
		return switch (_mode) {
			PinCodeMode.setup => 'Установите PIN-код',
			PinCodeMode.confirm => 'Повторите PIN-код',
			PinCodeMode.entry => 'Введите PIN-код',
		};
	}

	String get _subtitle {
		return switch (_mode) {
			PinCodeMode.setup => 'Придумайте PIN из 4 цифр для быстрого входа',
			PinCodeMode.confirm => 'Введите PIN ещё раз для подтверждения',
			PinCodeMode.entry => 'Введите PIN, чтобы продолжить',
		};
	}

	void _resetInput({String? errorMessage}) {
		setState(() {
			_digits.clear();
			_errorMessage = errorMessage;
		});
	}

	void _onDigit(String digit) {
		if (_digits.length >= _pinLength) {
			return;
		}

		setState(() {
			_digits.add(digit);
			_errorMessage = null;
		});

		if (_digits.length < _pinLength) {
			return;
		}

		final pin = _digits.join();
		Future<void>.delayed(const Duration(milliseconds: 200), () {
			if (!mounted) {
				return;
			}
			_handleCompletedPin(pin);
		});
	}

	Future<void> _handleCompletedPin(String pin) async {
		switch (_mode) {
			case PinCodeMode.setup:
				setState(() {
					_firstPin = pin;
					_mode = PinCodeMode.confirm;
					_digits.clear();
				});
			case PinCodeMode.confirm:
				if (pin == _firstPin) {
					final phoneDigits = widget.phoneDigits;
					if (phoneDigits == null || phoneDigits.length != 10) {
						_resetInput(errorMessage: 'Не удалось сохранить PIN. Войдите заново.');
						return;
					}

					await AuthSession.savePin(pin: pin, phoneDigits: phoneDigits);
					await _offerBiometricSetup();
					return;
				}

				setState(() {
					_mode = PinCodeMode.setup;
					_firstPin = null;
				});
				_resetInput(errorMessage: 'PIN-коды не совпадают. Попробуйте снова.');
			case PinCodeMode.entry:
				final phoneDigits = widget.phoneDigits;
				if (phoneDigits == null) {
					_resetInput(errorMessage: 'Войдите по номеру телефона');
					return;
				}

				final hasValidPin = await AuthSession.hasStoredPinForPhone(phoneDigits);
				if (!hasValidPin) {
					_resetInput(errorMessage: 'PIN не найден. Войдите по коду из Telegram.');
					return;
				}

				if (pin == AuthSession.pinCode) {
					if (!AuthSession.biometricEnabled &&
						await _biometricAuthService.canAuthenticate) {
						await _offerBiometricSetup();
						return;
					}

					_openHome();
					return;
				}

				_resetInput(errorMessage: 'Неверный PIN-код');
		}
	}

	void _openHome() {
		Navigator.of(context).pushAndRemoveUntil(
			MaterialPageRoute(builder: (context) => const MainShellScreen()),
			(_) => false,
		);
	}

	void _onBackspace() {
		if (_digits.isEmpty) {
			return;
		}

		setState(() {
			_digits.removeLast();
			_errorMessage = null;
		});
	}

	@override
	Widget build(BuildContext context) {
		return AuthScaffold(
			showBackButton: _mode != PinCodeMode.entry,
			body: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					const SizedBox(height: 8),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 24),
						child: Text(
							_title,
							style: const TextStyle(
								fontSize: 28,
								fontWeight: FontWeight.w700,
								color: AppColors.textPrimary,
							),
						),
					),
					const SizedBox(height: 12),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 24),
						child: Text(
							_subtitle,
							style: const TextStyle(
								fontSize: 15,
								height: 1.4,
								color: AppColors.textMuted,
							),
						),
					),
					const SizedBox(height: 40),
					CodeDots(
						length: _pinLength,
						filledCount: _digits.length,
					),
					if (_errorMessage != null) ...[
						const SizedBox(height: 16),
						Text(
							_errorMessage!,
							textAlign: TextAlign.center,
							style: const TextStyle(
								color: AppColors.error,
								fontSize: 14,
							),
						),
					],
					const Spacer(),
					if (_mode == PinCodeMode.entry &&
						_biometricAvailable &&
						AuthSession.biometricEnabled) ...[
						Padding(
							padding: const EdgeInsets.only(bottom: 16),
							child: TextButton.icon(
								onPressed: _isBiometricUnlocking ? null : _tryBiometricUnlock,
								icon: Icon(
									_biometricLabel == 'Face ID'
										? Icons.face_rounded
										: Icons.fingerprint_rounded,
									color: AppColors.primary,
								),
								label: Text(
									_isBiometricUnlocking
										? 'Проверяем $_biometricLabel...'
										: 'Войти по $_biometricLabel',
									style: const TextStyle(
										color: AppColors.primary,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
					],
					NumericKeypad(
						style: NumericKeypadStyle.plated,
						onDigit: _onDigit,
						onBackspace: _onBackspace,
					),
				],
			),
		);
	}
}
