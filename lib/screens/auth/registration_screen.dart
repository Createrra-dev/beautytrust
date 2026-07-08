import 'package:flutter/material.dart';

import '../../services/api/auth_api.dart';
import '../../services/api/beauty_trust_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/auth/auth_buttons.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/password_requirements.dart';
import '../../widgets/auth/phone_text_field.dart';
import 'otp_method_screen.dart';
import 'phone_login_screen.dart';

class RegistrationScreen extends StatefulWidget {
	const RegistrationScreen({
		super.key,
		this.initialPhoneDigits,
	});

	final String? initialPhoneDigits;

	@override
	State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
	final _authApi = AuthApi();
	final _firstNameController = TextEditingController();
	final _phoneController = TextEditingController();
	final _emailController = TextEditingController();
	final _passwordController = TextEditingController();
	final _confirmPasswordController = TextEditingController();

	var _obscurePassword = true;
	var _obscureConfirmPassword = true;
	var _isSubmitting = false;

	@override
	void initState() {
		super.initState();
		PhoneTextField.applyMaskToController(_phoneController);
		final initialPhoneDigits = widget.initialPhoneDigits;
		if (initialPhoneDigits != null && initialPhoneDigits.length == 10) {
			_phoneController.text = formatPhoneInput(initialPhoneDigits);
		}
	}

	@override
	void dispose() {
		_firstNameController.dispose();
		_phoneController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		_confirmPasswordController.dispose();
		super.dispose();
	}

	bool get _canRegister {
		final password = _passwordController.text;
		return _firstNameController.text.trim().isNotEmpty &&
			isPhoneComplete(_phoneController.text) &&
			PasswordRequirements.isValid(password) &&
			password == _confirmPasswordController.text;
	}

	bool get _passwordsMismatch {
		final confirmPassword = _confirmPasswordController.text;
		if (confirmPassword.isEmpty) {
			return false;
		}

		return _passwordController.text != confirmPassword;
	}

	Future<void> _register() async {
		if (!_canRegister || _isSubmitting) {
			return;
		}

		final phoneDigits = extractPhoneDigits(_phoneController.text);
		final firstName = _firstNameController.text.trim();

		setState(() => _isSubmitting = true);

		try {
			final isRegistered = await _authApi.isPhoneRegistered(phoneDigits);
			if (!mounted) {
				return;
			}

			if (isRegistered) {
				setState(() => _isSubmitting = false);
				await _showAlreadyRegisteredDialog(phoneDigits);
				return;
			}

			setState(() => _isSubmitting = false);

			Navigator.of(context).push(
				MaterialPageRoute(
					builder: (context) => OtpMethodScreen(
						phoneDigits: phoneDigits,
						firstName: firstName,
						isRegistration: true,
					),
				),
			);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}

			setState(() => _isSubmitting = false);
			AppSnackBar.show(context, error.message);
		}
	}

	Future<void> _showAlreadyRegisteredDialog(String phoneDigits) async {
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
							onPressed: () => Navigator.of(dialogContext).pop(),
							child: const Text('Отмена'),
						),
						TextButton(
							onPressed: () {
								Navigator.of(dialogContext).pop();
								Navigator.of(context).pushAndRemoveUntil(
									MaterialPageRoute(
										builder: (context) => OtpMethodScreen(
											phoneDigits: phoneDigits,
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
	}

	@override
	Widget build(BuildContext context) {
		return AuthScaffold(
			showBackButton: true,
			body: ListenableBuilder(
				listenable: Listenable.merge([
					_firstNameController,
					_phoneController,
					_emailController,
					_passwordController,
					_confirmPasswordController,
				]),
				builder: (context, _) {
					return SingleChildScrollView(
						padding: const EdgeInsets.symmetric(horizontal: 24),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								const SizedBox(height: 8),
								const Text(
									'Регистрация',
									textAlign: TextAlign.center,
									style: TextStyle(
										fontSize: 28,
										fontWeight: FontWeight.w700,
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: 12),
								const Text(
									'Создайте аккаунт, чтобы получить доступ ко всем возможностям BeautyTrust',
									textAlign: TextAlign.center,
									style: TextStyle(
										fontSize: 15,
										height: 1.4,
										color: AppColors.textMuted,
									),
								),
								const SizedBox(height: 28),
								AppTextField(
									label: 'Имя',
									controller: _firstNameController,
									hintText: 'Анна',
								),
								const SizedBox(height: 16),
								PhoneTextField(controller: _phoneController),
								const SizedBox(height: 16),
								AppTextField(
									label: 'Email (необязательно)',
									controller: _emailController,
									keyboardType: TextInputType.emailAddress,
									hintText: 'anna.petrova@mail.ru',
								),
								const SizedBox(height: 16),
								AppTextField(
									label: 'Пароль',
									controller: _passwordController,
									obscureText: _obscurePassword,
									suffix: IconButton(
										onPressed: () {
											setState(() => _obscurePassword = !_obscurePassword);
										},
										icon: Icon(
											_obscurePassword
												? Icons.visibility_outlined
												: Icons.visibility_off_outlined,
											color: AppColors.textMuted,
										),
									),
								),
								const SizedBox(height: 16),
								AppTextField(
									label: 'Подтвердите пароль',
									controller: _confirmPasswordController,
									obscureText: _obscureConfirmPassword,
									errorText: _passwordsMismatch ? 'Пароли не совпадают' : null,
									suffix: IconButton(
										onPressed: () {
											setState(
												() => _obscureConfirmPassword = !_obscureConfirmPassword,
											);
										},
										icon: Icon(
											_obscureConfirmPassword
												? Icons.visibility_outlined
												: Icons.visibility_off_outlined,
											color: AppColors.textMuted,
										),
									),
								),
								const SizedBox(height: 16),
								PasswordRequirements(password: _passwordController.text),
								const SizedBox(height: 24),
								PrimaryAuthButton(
									label: _isSubmitting ? 'Проверяем номер...' : 'Зарегистрироваться',
									onPressed: _canRegister && !_isSubmitting ? _register : null,
								),
								const SizedBox(height: 20),
								Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										const Text(
											'Уже есть аккаунт? ',
											style: TextStyle(color: AppColors.textMuted),
										),
										GestureDetector(
											onTap: () {
												Navigator.of(context).pushReplacement(
													MaterialPageRoute(
														builder: (context) => const PhoneLoginScreen(),
													),
												);
											},
											child: const Text(
												'Войти',
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
					);
				},
			),
		);
	}
}
