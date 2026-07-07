import 'package:flutter/material.dart';

import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth/auth_buttons.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/phone_text_field.dart';
import '../../widgets/brand_title.dart';
import 'otp_code_screen.dart';
import 'pin_code_screen.dart';
import 'registration_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
	const PhoneLoginScreen({super.key});

	@override
	State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
	final _phoneController = TextEditingController();

	@override
	void initState() {
		super.initState();
		_phoneController.addListener(_onPhoneChanged);
	}

	@override
	void dispose() {
		_phoneController.removeListener(_onPhoneChanged);
		_phoneController.dispose();
		super.dispose();
	}

	void _onPhoneChanged() {
		setState(() {});
	}

	void _continue() {
		final digits = extractPhoneDigits(_phoneController.text);
		if (digits.length != 10) {
			return;
		}

		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => OtpCodeScreen(phoneDigits: digits),
			),
		);
	}

	void _openRegistration() {
		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => const RegistrationScreen(),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final phoneComplete = isPhoneComplete(_phoneController.text);

		return AuthScaffold(
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						const SizedBox(height: 24),
						const Center(
							child: Column(
								children: [
									AppLogo(size: 72),
									SizedBox(height: 12),
									BrandTitle(fontSize: 24),
								],
							),
						),
						const SizedBox(height: 40),
						const Text(
							'Вход по телефону',
							textAlign: TextAlign.center,
							style: TextStyle(
								fontSize: 28,
								fontWeight: FontWeight.w700,
								color: AppColors.textPrimary,
							),
						),
						const SizedBox(height: 12),
						const Text(
							'Введите номер телефона, чтобы войти в аккаунт',
							textAlign: TextAlign.center,
							style: TextStyle(
								fontSize: 15,
								height: 1.4,
								color: AppColors.textMuted,
							),
						),
						const SizedBox(height: 28),
						PhoneTextField(controller: _phoneController),
						const SizedBox(height: 24),
						PrimaryAuthButton(
							label: 'Продолжить',
							onPressed: phoneComplete ? _continue : null,
						),
						const SizedBox(height: 24),
						const AuthDivider(),
						const SizedBox(height: 24),
						SocialAuthButton(
							label: 'Войти с Apple',
							icon: Icons.apple,
							onPressed: () {},
						),
						const SizedBox(height: 12),
						SocialAuthButton(
							label: 'Войти с Google',
							icon: Icons.g_mobiledata_rounded,
							onPressed: () {},
						),
						const SizedBox(height: 24),
						_wrapLegalText(context),
						const SizedBox(height: 16),
						if (AuthSession.pinCode != null)
							TextButton(
								onPressed: () {
									Navigator.of(context).push(
										MaterialPageRoute(
											builder: (context) => const PinCodeScreen(
												mode: PinCodeMode.entry,
											),
										),
									);
								},
								child: const Text('Войти по PIN-коду'),
							),
						const SizedBox(height: 8),
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const Text(
									'Нет аккаунта? ',
									style: TextStyle(color: AppColors.textMuted),
								),
								GestureDetector(
									onTap: _openRegistration,
									child: const Text(
										'Зарегистрироваться',
										style: TextStyle(
											color: AppColors.primary,
											fontWeight: FontWeight.w600,
										),
									),
								),
							],
						),
						const SizedBox(height: 24),
					],
				),
			),
		);
	}

	Widget _wrapLegalText(BuildContext context) {
		return RichText(
			textAlign: TextAlign.center,
			text: const TextSpan(
				style: TextStyle(
					color: AppColors.textMuted,
					fontSize: 12,
					height: 1.5,
				),
				children: [
					TextSpan(text: 'Продолжая, вы соглашаетесь с '),
					TextSpan(
						text: 'Пользовательским соглашением',
						style: TextStyle(color: AppColors.primary),
					),
					TextSpan(text: ' и '),
					TextSpan(
						text: 'Политикой конфиденциальности',
						style: TextStyle(color: AppColors.primary),
					),
				],
			),
		);
	}
}
