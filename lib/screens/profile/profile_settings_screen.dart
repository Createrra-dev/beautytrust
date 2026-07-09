import 'package:flutter/material.dart';

import '../../models/master_settings.dart';
import '../../services/api/app_api_repository.dart';
import '../../services/auth_session.dart';
import '../../services/biometric_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import 'yclients_integration_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
	const ProfileSettingsScreen({super.key});

	static const routeName = '/profile-settings';

	@override
	State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
	final _api = AppApiRepository();
	final _biometricAuthService = BiometricAuthService();

	MasterSettings? _settings;
	var _isLoading = true;
	var _biometricAvailable = false;
	var _biometricEnabled = false;
	var _biometricLabel = 'Face ID';
	String? _error;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_isLoading = true;
			_error = null;
		});

		await AuthSession.load();
		final canUseBiometric = await _biometricAuthService.canAuthenticate;
		final label = await _biometricAuthService.biometricLabel();

		try {
			final settings = await _api.fetchProfileSettings();
			if (!mounted) {
				return;
			}
			setState(() {
				_settings = settings;
				_biometricAvailable = canUseBiometric;
				_biometricEnabled = AuthSession.biometricEnabled;
				_biometricLabel = label;
				_isLoading = false;
			});
		} catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_error = error.toString();
				_isLoading = false;
			});
		}
	}

	Future<void> _updateSettings(MasterSettings updated) async {
		setState(() => _settings = updated);

		try {
			final saved = await _api.updateProfileSettings(updated);
			if (!mounted) {
				return;
			}
			setState(() => _settings = saved);
		} catch (error) {
			if (!mounted) {
				return;
			}
			AppSnackBar.show(
				context,
				error.toString(),
				type: AppSnackBarType.error,
			);
			await _load();
		}
	}

	Future<void> _toggleBiometric(bool enabled) async {
		if (enabled) {
			final result = await _biometricAuthService.authenticate(
				reason: 'Подтвердите включение $_biometricLabel',
			);
			if (result != BiometricUnlockResult.success) {
				return;
			}
		}

		await AuthSession.setBiometricEnabled(enabled);
		if (!mounted) {
			return;
		}
		setState(() => _biometricEnabled = enabled);
	}

	@override
	Widget build(BuildContext context) {
		final settings = _settings;

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
						child: Row(
							children: [
								IconButton(
									onPressed: () => Navigator.of(context).pop(),
									icon: const Icon(Icons.arrow_back_ios_new_rounded),
								),
								const Expanded(
									child: Text(
										'Настройки',
										textAlign: TextAlign.center,
										style: TextStyle(
											fontSize: 18,
											fontWeight: FontWeight.w600,
										),
									),
								),
								const SizedBox(width: 48),
							],
						),
					),
					Expanded(
						child: _isLoading
							? const Center(child: CircularProgressIndicator())
							: _error != null
								? Center(
									child: Text(
										_error!,
										style: const TextStyle(color: AppColors.error),
									),
								)
								: ListView(
									padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
									children: [
										_SettingsCard(
											title: 'Уведомления',
											children: [
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('Push-уведомления'),
													value: settings!.pushNotificationsEnabled,
													onChanged: (value) {
														_updateSettings(
															settings.copyWith(
																pushNotificationsEnabled: value,
															),
														);
													},
												),
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('Email-уведомления'),
													value: settings.emailNotificationsEnabled,
													onChanged: (value) {
														_updateSettings(
															settings.copyWith(
																emailNotificationsEnabled: value,
															),
														);
													},
												),
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('Маркетинговые рассылки'),
													value: settings.marketingNotificationsEnabled,
													onChanged: (value) {
														_updateSettings(
															settings.copyWith(
																marketingNotificationsEnabled: value,
															),
														);
													},
												),
											],
										),
										if (_biometricAvailable) ...[
											const SizedBox(height: 16),
											_SettingsCard(
												title: 'Безопасность',
												children: [
													SwitchListTile(
														contentPadding: EdgeInsets.zero,
														title: Text('Вход по $_biometricLabel'),
														value: _biometricEnabled,
														onChanged: _toggleBiometric,
													),
												],
											),
										],
										const SizedBox(height: 16),
										_SettingsCard(
											title: 'Интеграции',
											children: [
												ListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('YClients'),
													subtitle: const Text(
														'Загрузка записей из онлайн-записи YClients',
													),
													trailing: const Icon(
														Icons.chevron_right_rounded,
														color: AppColors.textMuted,
													),
													onTap: () {
														Navigator.of(context).pushNamed(
															YClientsIntegrationScreen.routeName,
														);
													},
												),
											],
										),
										const SizedBox(height: 16),
										_SettingsCard(
											title: 'Результаты визитов',
											children: [
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('Выставлять базовые ответы'),
													subtitle: const Text(
														'При открытии результата визита автоматически '
														'выбираются: вовремя, оплата да, поведение нет, '
														'чаевые нет — можно сразу сохранить.',
													),
													value: settings.visitResultDefaultsEnabled,
													onChanged: (value) {
														_updateSettings(
															settings.copyWith(
																visitResultDefaultsEnabled: value,
															),
														);
													},
												),
											],
										),
									],
								),
					),
				],
			),
		);
	}
}

class _SettingsCard extends StatelessWidget {
	const _SettingsCard({
		required this.title,
		required this.children,
	});

	final String title;
	final List<Widget> children;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Text(
						title,
						style: const TextStyle(
							fontSize: 16,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 8),
					...children,
				],
			),
		);
	}
}
