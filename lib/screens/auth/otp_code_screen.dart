import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/code_dots.dart';
import '../../widgets/auth/numeric_keypad.dart';
import 'pin_code_screen.dart';

class OtpCodeScreen extends StatefulWidget {
	const OtpCodeScreen({
		super.key,
		required this.phoneDigits,
	});

	final String phoneDigits;

	@override
	State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
	static const _codeLength = 4;

	final _digits = <String>[];
	var _secondsLeft = 45;
	Timer? _timer;

	@override
	void initState() {
		super.initState();
		_startTimer();
	}

	@override
	void dispose() {
		_timer?.cancel();
		super.dispose();
	}

	void _startTimer() {
		_timer?.cancel();
		setState(() => _secondsLeft = 45);
		_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
			if (_secondsLeft == 0) {
				timer.cancel();
				return;
			}
			setState(() => _secondsLeft -= 1);
		});
	}

	void _onDigit(String digit) {
		if (_digits.length >= _codeLength) {
			return;
		}

		setState(() => _digits.add(digit));

		if (_digits.length == _codeLength) {
			Future<void>.delayed(const Duration(milliseconds: 250), () {
				if (!mounted) {
					return;
				}

				Navigator.of(context).push(
					MaterialPageRoute(
						builder: (context) => const PinCodeScreen(mode: PinCodeMode.setup),
					),
				);
			});
		}
	}

	void _onBackspace() {
		if (_digits.isEmpty) {
			return;
		}

		setState(() => _digits.removeLast());
	}

	String get _formattedTimer {
		final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
		final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
		return '$minutes:$seconds';
	}

	@override
	Widget build(BuildContext context) {
		final phone = formatPhoneDisplay(widget.phoneDigits);

		return AuthScaffold(
			showBackButton: true,
			body: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					const SizedBox(height: 8),
					const Padding(
						padding: EdgeInsets.symmetric(horizontal: 24),
						child: Text(
							'Введите код',
							style: TextStyle(
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
							'Мы отправили код из 4 цифр на номер $phone',
							style: const TextStyle(
								fontSize: 15,
								height: 1.4,
								color: AppColors.textMuted,
							),
						),
					),
					const SizedBox(height: 40),
					CodeDots(
						length: _codeLength,
						filledCount: _digits.length,
					),
					const SizedBox(height: 24),
					GestureDetector(
						onTap: _secondsLeft == 0 ? _startTimer : null,
						child: Text(
							_secondsLeft == 0
								? 'Отправить код повторно'
								: 'Отправить код повторно $_formattedTimer',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: _secondsLeft == 0
									? AppColors.primary
									: AppColors.textMuted,
								fontWeight: FontWeight.w500,
							),
						),
					),
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
