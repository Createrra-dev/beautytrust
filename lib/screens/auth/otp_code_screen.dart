import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/otp_delivery_channel.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/beauty_trust_api.dart';
import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth/auth_buttons.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/code_dots.dart';
import '../../widgets/auth/numeric_keypad.dart';
import '../home/main_shell_screen.dart';
import 'otp_method_screen.dart';
import 'pin_code_screen.dart';

class OtpCodeScreen extends StatefulWidget {
	const OtpCodeScreen({
		super.key,
		required this.phoneDigits,
		this.firstName,
		this.isRegistration = false,
		this.initialChannel = OtpDeliveryChannel.telegram,
	});

	final String phoneDigits;
	final String? firstName;
	final bool isRegistration;
	final OtpDeliveryChannel initialChannel;

	@override
	State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
	static const _codeLength = 4;

	final _authApi = AuthApi();
	final _digits = <String>[];

	var _secondsLeft = 0;
	var _isLoading = true;
	var _isVerifying = false;
	var _codeSent = false;
	var _channel = OtpDeliveryChannel.telegram;
	String? _sessionId;
	String? _botUrl;
	String? _errorText;
	String? _callStatusText;
	var _callCompleted = false;
	Timer? _timer;
	Timer? _callStatusTimer;

	@override
	void initState() {
		super.initState();
		_channel = widget.initialChannel;
		_requestOtp(clearAuth: true);
	}

	@override
	void dispose() {
		_timer?.cancel();
		_callStatusTimer?.cancel();
		super.dispose();
	}

	Future<void> _requestOtp({
		OtpDeliveryChannel? channel,
		bool clearAuth = false,
	}) async {
		if (channel != null) {
			_channel = channel;
		}

		if (clearAuth) {
			await AuthSession.clearAuth();
		}

		setState(() {
			_isLoading = true;
			_errorText = null;
			_digits.clear();
			_callStatusText = null;
			_callCompleted = false;
		});

		_callStatusTimer?.cancel();

		try {
			final result = await _authApi.sendOtp(
				widget.phoneDigits,
				channel: _channel,
				isRegistration: widget.isRegistration,
			);
			if (!mounted) {
				return;
			}

			setState(() {
				_sessionId = result.sessionId;
				_botUrl = result.botUrl;
				_codeSent = result.codeSent;
				_secondsLeft = result.expiresIn;
				_channel = result.channel;
				_isLoading = false;
			});
			_startTimer();

			if (_channel == OtpDeliveryChannel.telegram &&
				!result.codeSent &&
				result.botUrl.isNotEmpty) {
				await _openTelegramBot(result.botUrl);
			}

			if (_channel == OtpDeliveryChannel.flashCall && result.codeSent) {
				_startCallStatusPolling();
			}
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_isLoading = false;
				_errorText = error.message;
			});
		}
	}

	void _startTimer() {
		_timer?.cancel();
		_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
			if (_secondsLeft == 0) {
				timer.cancel();
				return;
			}
			setState(() => _secondsLeft -= 1);
		});
	}

	void _startCallStatusPolling() {
		_callStatusTimer?.cancel();
		_pollCallStatus();
		_callStatusTimer = Timer.periodic(
			const Duration(seconds: 3),
			(_) => _pollCallStatus(),
		);
	}

	Future<void> _pollCallStatus() async {
		final sessionId = _sessionId;
		if (sessionId == null || _channel != OtpDeliveryChannel.flashCall) {
			return;
		}

		try {
			final status = await _authApi.fetchCallStatus(sessionId);
			if (!mounted) {
				return;
			}

			setState(() {
				_callStatusText = status.callStatusDisplay ?? status.dialStatusDisplay;
				_callCompleted = status.completed;
			});

			if (status.completed) {
				_callStatusTimer?.cancel();
			}
		} on ApiException {
			return;
		}
	}

	Future<void> _openTelegramBot(String botUrl) async {
		final uri = Uri.parse(botUrl);
		if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
			if (!mounted) {
				return;
			}
			AppSnackBar.show(context, 'Не удалось открыть Telegram');
		}
	}

	String _buildSubtitle(String phone) {
		if (_channel == OtpDeliveryChannel.flashCall) {
			if (widget.isRegistration) {
				return _codeSent
					? 'Вам поступит звонок на номер $phone. Введите последние 4 цифры входящего номера.'
					: 'Инициируем звонок на номер $phone. Введите последние 4 цифры входящего номера.';
			}

			return _codeSent
				? 'Вам поступит звонок на номер $phone. Введите последние 4 цифры входящего номера.'
				: 'Инициируем звонок на номер $phone. Введите последние 4 цифры входящего номера.';
		}

		if (widget.isRegistration) {
			return _codeSent
				? 'Подтвердите регистрацию: код из 4 цифр отправлен в Telegram на номер $phone'
				: 'Подтвердите регистрацию в Telegram — код придёт на номер $phone';
		}

		return _codeSent
			? 'Мы отправили код из 4 цифр в Telegram на номер $phone'
			: 'Откройте бота Beauty Trust в Telegram — код придёт на номер $phone';
	}

	Future<void> _onDigit(String digit) async {
		if (_isLoading || _isVerifying || _digits.length >= _codeLength) {
			return;
		}

		setState(() => _digits.add(digit));

		if (_digits.length != _codeLength) {
			return;
		}

		final sessionId = _sessionId;
		if (sessionId == null) {
			setState(() {
				_errorText = 'Сессия не найдена. Запросите код повторно.';
				_digits.clear();
			});
			return;
		}

		setState(() {
			_isVerifying = true;
			_errorText = null;
		});

		try {
			final result = await _authApi.verifyOtp(
				sessionId: sessionId,
				code: _digits.join(),
				phoneDigits: widget.phoneDigits,
				firstName: widget.isRegistration ? widget.firstName : null,
			);

			if (result.isNewUser || widget.isRegistration) {
				await AuthSession.clearPin();
			}

			await AuthSession.saveAuth(
				token: result.accessToken,
				savedMasterId: result.masterId,
			);

			if (!mounted) {
				return;
			}

			final navigator = Navigator.of(context);

			if (widget.isRegistration && !result.isNewUser) {
				await AuthSession.clearAll();
				if (!mounted) {
					return;
				}

				await showDialog<void>(
					context: context,
					builder: (dialogContext) {
						return AlertDialog(
							title: const Text('Вы уже зарегистрированы'),
							content: const Text(
								'Войдите в аккаунт, чтобы начать пользоваться программой.',
							),
							actions: [
								TextButton(
									onPressed: () {
										Navigator.of(dialogContext).pop();
										navigator.pushAndRemoveUntil(
											MaterialPageRoute(
												builder: (context) => OtpMethodScreen(
													phoneDigits: widget.phoneDigits,
												),
											),
											(_) => false,
										);
									},
									child: const Text('Войти'),
								),
							],
						);
					},
				);
				return;
			}

			if (result.isNewUser || widget.isRegistration) {
				navigator.pushAndRemoveUntil(
					MaterialPageRoute(
						builder: (context) => PinCodeScreen(
							mode: PinCodeMode.setup,
							phoneDigits: widget.phoneDigits,
						),
					),
					(_) => false,
				);
				return;
			}

			await AuthSession.load();

			if (!mounted) {
				return;
			}

			if (AuthSession.hasStoredPin) {
				navigator.pushAndRemoveUntil(
					MaterialPageRoute(
						builder: (context) => PinCodeScreen(
							mode: PinCodeMode.entry,
							phoneDigits: AuthSession.pinPhoneDigits,
							tryBiometricOnOpen: true,
						),
					),
					(_) => false,
				);
				return;
			}

			navigator.pushAndRemoveUntil(
				MaterialPageRoute(builder: (context) => const MainShellScreen()),
				(_) => false,
			);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_isVerifying = false;
				_errorText = _mapAuthError(error.message);
				_digits.clear();
			});
		}
	}

	void _onBackspace() {
		if (_digits.isEmpty || _isVerifying) {
			return;
		}

		setState(() => _digits.removeLast());
	}

	String get _formattedTimer {
		final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
		final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
		return '$minutes:$seconds';
	}

	String _mapAuthError(String message) {
		if (message.contains('expired') || message.contains('истёк')) {
			return 'Код истёк. Нажмите «Отправить повторно».';
		}
		if (message.contains('Invalid code') || message.contains('Неверный')) {
			if (_channel == OtpDeliveryChannel.flashCall) {
				return 'Неверный код. Проверьте последние 4 цифры входящего номера.';
			}

			return 'Неверный код. Проверьте последнее сообщение в Telegram.';
		}
		return message;
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
							_buildSubtitle(phone),
							style: const TextStyle(
								fontSize: 15,
								height: 1.4,
								color: AppColors.textMuted,
							),
						),
					),
					if (_channel == OtpDeliveryChannel.flashCall && _callStatusText != null) ...[
						const SizedBox(height: 12),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Icon(
										_callCompleted
											? Icons.check_circle_outline_rounded
											: Icons.phone_in_talk_outlined,
										size: 18,
										color: _callCompleted
											? AppColors.secondary
											: AppColors.primary,
									),
									const SizedBox(width: 8),
									Flexible(
										child: Text(
											_callStatusText!,
											textAlign: TextAlign.center,
											style: TextStyle(
												fontSize: 14,
												fontWeight: FontWeight.w600,
												color: _callCompleted
													? AppColors.secondary
													: AppColors.primary,
											),
										),
									),
								],
							),
						),
					],
					if (_errorText != null) ...[
						const SizedBox(height: 12),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24),
							child: Text(
								_errorText!,
								style: const TextStyle(color: AppColors.error, fontSize: 14),
							),
						),
					],
					const SizedBox(height: 32),
					if (_isLoading)
						const Center(child: CircularProgressIndicator())
					else ...[
						CodeDots(
							length: _codeLength,
							filledCount: _digits.length,
						),
						const SizedBox(height: 20),
						if (_channel == OtpDeliveryChannel.telegram &&
							_botUrl != null &&
							!_codeSent)
							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 24),
								child: PrimaryAuthButton(
									label: 'Открыть Telegram',
									onPressed: () => _openTelegramBot(_botUrl!),
								),
							),
						const SizedBox(height: 16),
						GestureDetector(
							onTap: !_isLoading && _secondsLeft == 0
								? () => _requestOtp()
								: null,
							child: Text(
								_secondsLeft == 0
									? 'Отправить повторно'
									: 'Отправить повторно $_formattedTimer',
								textAlign: TextAlign.center,
								style: TextStyle(
									color: _secondsLeft == 0
										? AppColors.primary
										: AppColors.textMuted,
									fontWeight: FontWeight.w500,
								),
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
