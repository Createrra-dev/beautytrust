import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/auth/auth_buttons.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/password_requirements.dart';
import '../../widgets/auth/phone_text_field.dart';
import 'phone_login_screen.dart';
import 'pin_code_screen.dart';

class RegistrationScreen extends StatefulWidget {
	const RegistrationScreen({super.key});

	@override
	State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
	final _firstNameController = TextEditingController(text: 'Анна');
	final _lastNameController = TextEditingController(text: 'Петрова');
	final _phoneController = TextEditingController(text: '9991234567');
	final _emailController = TextEditingController(text: 'anna.petrova@mail.ru');
	final _passwordController = TextEditingController(text: 'Beauty123');
	final _confirmPasswordController = TextEditingController(text: 'Beauty123');

	var _obscurePassword = true;
	var _obscureConfirmPassword = true;

	@override
	void initState() {
		super.initState();
		PhoneTextField.applyMaskToController(_phoneController);
	}

	@override
	void dispose() {
		_firstNameController.dispose();
		_lastNameController.dispose();
		_phoneController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		_confirmPasswordController.dispose();
		super.dispose();
	}

	bool get _canRegister {
		final password = _passwordController.text;
		return _firstNameController.text.trim().isNotEmpty &&
			_lastNameController.text.trim().isNotEmpty &&
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

	void _register() {
		if (!_canRegister) {
			return;
		}

		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => const PinCodeScreen(mode: PinCodeMode.setup),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return AuthScaffold(
			showBackButton: true,
			body: ListenableBuilder(
				listenable: Listenable.merge([
					_firstNameController,
					_lastNameController,
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
								AppTextField(
									label: 'Фамилия',
									controller: _lastNameController,
									hintText: 'Петрова',
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
									label: 'Зарегистрироваться',
									onPressed: _canRegister ? _register : null,
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
