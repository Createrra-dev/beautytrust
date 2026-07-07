import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/code_dots.dart';
import '../../widgets/auth/numeric_keypad.dart';
import '../../services/auth_session.dart';
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
	});

	final PinCodeMode mode;
	final String? initialPin;

	@override
	State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
	static const _pinLength = 4;

	late PinCodeMode _mode;
	final _digits = <String>[];
	String? _firstPin;
	String? _errorMessage;

	@override
	void initState() {
		super.initState();
		_mode = widget.mode;
		_firstPin = widget.initialPin;
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

	void _handleCompletedPin(String pin) {
		switch (_mode) {
			case PinCodeMode.setup:
				setState(() {
					_firstPin = pin;
					_mode = PinCodeMode.confirm;
					_digits.clear();
				});
			case PinCodeMode.confirm:
				if (pin == _firstPin) {
					AuthSession.pinCode = pin;
					_openHome();
					return;
				}

				setState(() {
					_mode = PinCodeMode.setup;
					_firstPin = null;
				});
				_resetInput(errorMessage: 'PIN-коды не совпадают. Попробуйте снова.');
			case PinCodeMode.entry:
				if (pin == AuthSession.pinCode) {
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
