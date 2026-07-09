import 'package:flutter/material.dart';

import '../../models/yclients_integration.dart';
import '../../services/api/app_api_repository.dart';
import '../../services/api/beauty_trust_api.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';

class YClientsIntegrationScreen extends StatefulWidget {
	const YClientsIntegrationScreen({super.key});

	static const routeName = '/yclients-integration';

	@override
	State<YClientsIntegrationScreen> createState() => _YClientsIntegrationScreenState();
}

class _YClientsIntegrationScreenState extends State<YClientsIntegrationScreen> {
	final _api = AppApiRepository();
	final _partnerTokenController = TextEditingController();
	final _companyIdController = TextEditingController();
	final _loginController = TextEditingController();
	final _passwordController = TextEditingController();

	YClientsIntegration? _integration;
	var _enabled = false;
	var _isLoading = true;
	var _isSaving = false;
	var _isSyncing = false;
	String? _error;

	@override
	void initState() {
		super.initState();
		_load();
	}

	@override
	void dispose() {
		_partnerTokenController.dispose();
		_companyIdController.dispose();
		_loginController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _load() async {
		setState(() {
			_isLoading = true;
			_error = null;
		});

		try {
			final integration = await _api.fetchYClientsIntegration();
			if (!mounted) {
				return;
			}
			setState(() {
				_integration = integration;
				_enabled = integration.enabled;
				_partnerTokenController.text = integration.partnerToken;
				_companyIdController.text = integration.companyId;
				_loginController.text = integration.login;
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

	Future<void> _save() async {
		if (_isSaving) {
			return;
		}

		setState(() => _isSaving = true);

		try {
			final integration = await _api.updateYClientsIntegration(
				enabled: _enabled,
				partnerToken: _partnerTokenController.text.trim(),
				companyId: _companyIdController.text.trim(),
				login: _loginController.text.trim(),
				password: _passwordController.text.trim().isEmpty
					? null
					: _passwordController.text.trim(),
			);
			if (!mounted) {
				return;
			}

			_passwordController.clear();
			setState(() {
				_integration = integration;
				_isSaving = false;
			});

			await DashboardDataService.syncFromApi();
			if (!mounted) {
				return;
			}

			AppSnackBar.show(
				context,
				_enabled
					? 'Интеграция YClients сохранена, записи синхронизированы'
					: 'Интеграция YClients отключена',
				type: AppSnackBarType.success,
			);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() => _isSaving = false);
			AppSnackBar.show(context, error.message, type: AppSnackBarType.error);
		} catch (error) {
			if (!mounted) {
				return;
			}
			setState(() => _isSaving = false);
			AppSnackBar.show(context, error.toString(), type: AppSnackBarType.error);
		}
	}

	Future<void> _syncNow() async {
		if (_isSyncing) {
			return;
		}

		setState(() => _isSyncing = true);

		try {
			final result = await _api.syncYClientsIntegration();
			await DashboardDataService.syncFromApi();
			await _load();
			if (!mounted) {
				return;
			}
			setState(() => _isSyncing = false);
			AppSnackBar.show(
				context,
				'Синхронизация: ${result.imported} новых, ${result.updated} обновлено',
				type: AppSnackBarType.success,
			);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() => _isSyncing = false);
			AppSnackBar.show(context, error.message, type: AppSnackBarType.error);
		} catch (error) {
			if (!mounted) {
				return;
			}
			setState(() => _isSyncing = false);
			AppSnackBar.show(context, error.toString(), type: AppSnackBarType.error);
		}
	}

	@override
	Widget build(BuildContext context) {
		final integration = _integration;

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
										'Интеграция YClients',
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
											children: [
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('Включить интеграцию'),
													subtitle: const Text(
														'Загружать будущие записи из YClients '
														'и показывать их в текущих записях.',
													),
													value: _enabled,
													onChanged: (value) {
														setState(() => _enabled = value);
													},
												),
											],
										),
										if (_enabled) ...[
											const SizedBox(height: 16),
											_SettingsCard(
												title: 'Данные подключения',
												children: [
													_buildField(
														controller: _partnerTokenController,
														label: 'Partner Token',
														hint: 'Партнёрский токен YClients',
													),
													const SizedBox(height: 12),
													_buildField(
														controller: _companyIdController,
														label: 'Company ID (CID)',
														hint: '40430',
														keyboardType: TextInputType.number,
													),
													const SizedBox(height: 12),
													_buildField(
														controller: _loginController,
														label: 'Логин администратора YClients',
														hint: 'email@example.com',
													),
													const SizedBox(height: 12),
													_buildField(
														controller: _passwordController,
														label: 'Пароль YClients',
														hint: integration?.hasUserToken == true
															? 'Оставьте пустым, если не меняли'
															: 'Нужен для получения User Token',
														obscureText: true,
													),
												],
											),
											if (integration != null &&
												(integration.lastSyncAt != null ||
													integration.hasUserToken)) ...[
												const SizedBox(height: 16),
												_SettingsCard(
													title: 'Статус',
													children: [
														if (integration.hasUserToken)
															const Text(
																'User Token получен',
																style: TextStyle(
																	color: AppColors.secondary,
																	fontWeight: FontWeight.w600,
																),
															),
														if (integration.lastSyncAt != null) ...[
															const SizedBox(height: 8),
															Text(
																'Последняя синхронизация: '
																'${_formatDateTime(integration.lastSyncAt!)}',
																style: const TextStyle(
																	color: AppColors.textMuted,
																	fontSize: 13,
																),
															),
															Text(
																'Загружено записей: ${integration.lastSyncCount}',
																style: const TextStyle(
																	color: AppColors.textMuted,
																	fontSize: 13,
																),
															),
														],
														const SizedBox(height: 12),
														OutlinedButton(
															onPressed: _isSyncing ? null : _syncNow,
															child: _isSyncing
																? const SizedBox(
																	width: 20,
																	height: 20,
																	child: CircularProgressIndicator(
																		strokeWidth: 2,
																	),
																)
																: const Text('Синхронизировать сейчас'),
														),
													],
												),
											],
										],
									],
								),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
						child: FilledButton(
							onPressed: _isSaving || _isLoading ? null : _save,
							child: _isSaving
								? const SizedBox(
									width: 22,
									height: 22,
									child: CircularProgressIndicator(
										strokeWidth: 2,
										color: AppColors.textPrimary,
									),
								)
								: const Text('Сохранить'),
						),
					),
				],
			),
		);
	}

	Widget _buildField({
		required TextEditingController controller,
		required String label,
		required String hint,
		TextInputType keyboardType = TextInputType.text,
		bool obscureText = false,
	}) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Text(
					label,
					style: const TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.w600,
					),
				),
				const SizedBox(height: 6),
				TextField(
					controller: controller,
					keyboardType: keyboardType,
					obscureText: obscureText,
					style: const TextStyle(color: AppColors.textPrimary),
					decoration: InputDecoration(
						hintText: hint,
						hintStyle: const TextStyle(color: AppColors.textMuted),
						filled: true,
						fillColor: AppColors.surfaceElevated,
						border: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: const BorderSide(color: AppColors.border),
						),
						enabledBorder: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: const BorderSide(color: AppColors.border),
						),
						focusedBorder: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: const BorderSide(color: AppColors.primary),
						),
					),
				),
			],
		);
	}

	String _formatDateTime(DateTime value) {
		final local = value.toLocal();
		return '${local.day.toString().padLeft(2, '0')}.'
			'${local.month.toString().padLeft(2, '0')}.'
			'${local.year} '
			'${local.hour.toString().padLeft(2, '0')}:'
			'${local.minute.toString().padLeft(2, '0')}';
	}
}

class _SettingsCard extends StatelessWidget {
	const _SettingsCard({
		this.title,
		required this.children,
	});

	final String? title;
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
					if (title != null) ...[
						Text(
							title!,
							style: const TextStyle(
								fontSize: 16,
								fontWeight: FontWeight.w600,
							),
						),
						const SizedBox(height: 12),
					],
					...children,
				],
			),
		);
	}
}
