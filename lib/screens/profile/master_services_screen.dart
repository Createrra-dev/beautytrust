import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/master_services_data.dart';
import '../../models/appointment_record.dart';
import '../../models/master_service.dart';
import '../../services/api/beauty_trust_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/auth/auth_buttons.dart';

class MasterServicesScreen extends StatefulWidget {
	const MasterServicesScreen({super.key});

	static const routeName = '/master-services';

	@override
	State<MasterServicesScreen> createState() => _MasterServicesScreenState();
}

class _MasterServicesScreenState extends State<MasterServicesScreen> {
	List<MasterService> _services = [];
	var _isLoading = true;
	String? _errorText;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_isLoading = true;
			_errorText = null;
		});

		try {
			final services = await MasterServicesData.load(force: true);
			if (!mounted) {
				return;
			}
			setState(() {
				_services = services;
				_isLoading = false;
			});
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorText = error.message;
				_isLoading = false;
			});
		} catch (_) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorText = 'Не удалось загрузить услуги';
				_isLoading = false;
			});
		}
	}

	Future<void> _openEditor({MasterService? service}) async {
		final result = await showModalBottomSheet<MasterService>(
			context: context,
			isScrollControlled: true,
			backgroundColor: AppColors.surfaceElevated,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) => _ServiceEditorSheet(service: service),
		);

		if (!mounted || result == null) {
			return;
		}

		await _load();
		if (!mounted) {
			return;
		}
		AppSnackBar.show(
			context,
			service == null ? 'Услуга добавлена' : 'Услуга обновлена',
			type: AppSnackBarType.success,
		);
	}

	Future<void> _confirmDelete(MasterService service) async {
		final id = service.id;
		if (id == null || !service.isOwned) {
			AppSnackBar.show(
				context,
				'Можно удалять только свои услуги',
				type: AppSnackBarType.error,
			);
			return;
		}

		final confirmed = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Удалить услугу?'),
					content: Text('«${service.name}» будет удалена.'),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Отмена'),
						),
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							child: const Text(
								'Удалить',
								style: TextStyle(color: AppColors.error),
							),
						),
					],
				);
			},
		);

		if (confirmed != true || !mounted) {
			return;
		}

		try {
			await MasterServicesData.delete(id);
			if (!mounted) {
				return;
			}
			setState(() {
				_services = _services.where((item) => item.id != id).toList();
			});
			AppSnackBar.show(
				context,
				'Услуга удалена',
				type: AppSnackBarType.success,
			);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			AppSnackBar.show(context, error.message, type: AppSnackBarType.error);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () => _openEditor(),
				backgroundColor: AppColors.primary,
				foregroundColor: AppColors.textPrimary,
				icon: const Icon(Icons.add_rounded),
				label: const Text('Добавить'),
			),
			body: SafeArea(
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						_PageHeader(
							title: 'Мои услуги',
							onBack: () => Navigator.of(context).pop(),
						),
						Expanded(
							child: _isLoading
								? const Center(child: CircularProgressIndicator())
								: _errorText != null
									? Center(
										child: Padding(
											padding: const EdgeInsets.all(24),
											child: Column(
												mainAxisSize: MainAxisSize.min,
												children: [
													Text(
														_errorText!,
														textAlign: TextAlign.center,
														style: const TextStyle(color: AppColors.error),
													),
													const SizedBox(height: 16),
													PrimaryAuthButton(
														label: 'Повторить',
														onPressed: _load,
													),
												],
											),
										),
									)
									: RefreshIndicator(
										onRefresh: _load,
										child: _services.isEmpty
											? ListView(
												physics: const AlwaysScrollableScrollPhysics(),
												children: const [
													SizedBox(height: 120),
													Icon(
														Icons.spa_outlined,
														size: 48,
														color: AppColors.textMuted,
													),
													SizedBox(height: 12),
													Text(
														'Пока нет услуг',
														textAlign: TextAlign.center,
														style: TextStyle(
															color: AppColors.textMuted,
															fontSize: 16,
														),
													),
													SizedBox(height: 8),
													Text(
														'Добавьте первую услугу кнопкой ниже',
														textAlign: TextAlign.center,
														style: TextStyle(
															color: AppColors.textMuted,
															fontSize: 14,
														),
													),
												],
											)
											: ListView.separated(
												physics: const AlwaysScrollableScrollPhysics(),
												padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
												itemCount: _services.length,
												separatorBuilder: (context, index) => const SizedBox(height: 10),
												itemBuilder: (context, index) {
													final service = _services[index];
													return _ServiceTile(
														service: service,
														onEdit: () => _openEditor(service: service),
														onDelete: service.isOwned
															? () => _confirmDelete(service)
															: null,
													);
												},
											),
									),
						),
					],
				),
			),
		);
	}
}

class _PageHeader extends StatelessWidget {
	const _PageHeader({
		required this.title,
		required this.onBack,
	});

	final String title;
	final VoidCallback onBack;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
			child: Row(
				children: [
					IconButton(
						onPressed: onBack,
						icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
						color: AppColors.textPrimary,
					),
					Expanded(
						child: Text(
							title,
							textAlign: TextAlign.center,
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 18,
								fontWeight: FontWeight.w600,
							),
						),
					),
					const SizedBox(width: 48),
				],
			),
		);
	}
}

class _ServiceTile extends StatelessWidget {
	const _ServiceTile({
		required this.service,
		required this.onEdit,
		this.onDelete,
	});

	final MasterService service;
	final VoidCallback onEdit;
	final VoidCallback? onDelete;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.surface,
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				onTap: onEdit,
				borderRadius: BorderRadius.circular(14),
				child: Container(
					padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: AppColors.border),
					),
					child: Row(
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											service.name,
											style: const TextStyle(
												color: AppColors.textPrimary,
												fontSize: 16,
												fontWeight: FontWeight.w600,
											),
										),
										const SizedBox(height: 6),
										Text(
											'${service.durationLabel} · ${formatServicePrice(service.price)}',
											style: const TextStyle(
												color: AppColors.textMuted,
												fontSize: 14,
											),
										),
										if (!service.isOwned) ...[
											const SizedBox(height: 6),
											const Text(
												'Общий каталог · при сохранении станет вашей',
												style: TextStyle(
													color: AppColors.secondary,
													fontSize: 12,
												),
											),
										],
									],
								),
							),
							IconButton(
								onPressed: onEdit,
								icon: const Icon(Icons.edit_outlined, size: 20),
								color: AppColors.textMuted,
							),
							if (onDelete != null)
								IconButton(
									onPressed: onDelete,
									icon: const Icon(Icons.delete_outline_rounded, size: 20),
									color: AppColors.error,
								),
						],
					),
				),
			),
		);
	}
}

class _ServiceEditorSheet extends StatefulWidget {
	const _ServiceEditorSheet({this.service});

	final MasterService? service;

	@override
	State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
	late final TextEditingController _nameController;
	late final TextEditingController _durationController;
	late final TextEditingController _priceController;
	String? _errorText;
	var _isSaving = false;

	@override
	void initState() {
		super.initState();
		final service = widget.service;
		_nameController = TextEditingController(text: service?.name ?? '');
		_durationController = TextEditingController(text: service?.durationLabel ?? '');
		_priceController = TextEditingController(
			text: service == null ? '' : '${service.price}',
		);
	}

	@override
	void dispose() {
		_nameController.dispose();
		_durationController.dispose();
		_priceController.dispose();
		super.dispose();
	}

	Future<void> _save() async {
		final name = _nameController.text.trim();
		final duration = _durationController.text.trim();
		final priceText = _priceController.text.replaceAll(RegExp(r'\s'), '');
		final price = int.tryParse(priceText);

		if (name.length < 2) {
			setState(() => _errorText = 'Введите название услуги');
			return;
		}
		if (duration.isEmpty) {
			setState(() => _errorText = 'Укажите длительность');
			return;
		}
		if (price == null || price < 0) {
			setState(() => _errorText = 'Укажите корректную цену');
			return;
		}

		setState(() {
			_errorText = null;
			_isSaving = true;
		});

		try {
			final existing = widget.service;
			final MasterService saved;
			if (existing?.id != null) {
				saved = await MasterServicesData.update(
					serviceId: existing!.id!,
					name: name,
					durationLabel: duration,
					price: price,
				);
			} else {
				saved = await MasterServicesData.create(
					name: name,
					durationLabel: duration,
					price: price,
				);
			}
			if (!mounted) {
				return;
			}
			Navigator.of(context).pop(saved);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorText = error.message;
				_isSaving = false;
			});
		} catch (_) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorText = 'Не удалось сохранить услугу';
				_isSaving = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
		final isEdit = widget.service != null;

		return Padding(
			padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Center(
						child: Container(
							width: 40,
							height: 4,
							decoration: BoxDecoration(
								color: AppColors.border,
								borderRadius: BorderRadius.circular(2),
							),
						),
					),
					const SizedBox(height: 16),
					Text(
						isEdit ? 'Редактирование услуги' : 'Новая услуга',
						textAlign: TextAlign.center,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 18,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 16),
					AppTextField(
						label: 'Название',
						controller: _nameController,
						hintText: 'Маникюр + покрытие',
					),
					const SizedBox(height: 12),
					AppTextField(
						label: 'Длительность',
						controller: _durationController,
						hintText: '1 ч 30 мин',
					),
					const SizedBox(height: 12),
					AppTextField(
						label: 'Цена, ₽',
						controller: _priceController,
						hintText: '2500',
						keyboardType: TextInputType.number,
						inputFormatters: [FilteringTextInputFormatter.digitsOnly],
					),
					if (_errorText != null) ...[
						const SizedBox(height: 12),
						Text(
							_errorText!,
							style: const TextStyle(color: AppColors.error, fontSize: 14),
						),
					],
					const SizedBox(height: 20),
					PrimaryAuthButton(
						label: _isSaving ? 'Сохранение…' : 'Сохранить',
						onPressed: _isSaving ? null : _save,
					),
				],
			),
		);
	}
}
