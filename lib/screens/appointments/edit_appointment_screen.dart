import 'package:flutter/material.dart';

import '../../data/master_services_data.dart';
import '../../models/appointment_record.dart';
import '../../models/master_service.dart';
import '../../services/client_profile_service.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';

class EditAppointmentScreen extends StatefulWidget {
	const EditAppointmentScreen({
		super.key,
		required this.appointment,
	});

	final AppointmentRecord appointment;

	@override
	State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
	final _nameController = TextEditingController();
	final _phoneController = TextEditingController();
	final _phoneFocusNode = FocusNode();

	late DateTime _selectedDate;
	late TimeOfDay _selectedTime;
	MasterService? _selectedService;
	List<MasterService> _services = [];
	String? _errorText;
	var _isLoadingServices = true;

	@override
	void initState() {
		super.initState();
		final appointment = widget.appointment;
		_nameController.text = appointment.clientName;
		_phoneController.text = formatPhoneInput(appointment.clientPhoneDigits);
		_selectedDate = appointment.scheduledAt;
		_selectedTime = TimeOfDay(
			hour: appointment.scheduledAt.hour,
			minute: appointment.scheduledAt.minute,
		);
		_loadServices();
	}

	Future<void> _loadServices() async {
		final services = await MasterServicesData.load();
		if (!mounted) {
			return;
		}
		setState(() {
			_services = services;
			_selectedService = MasterServicesData.findByName(widget.appointment.serviceName) ??
				(services.isNotEmpty ? services.first : null);
			_isLoadingServices = false;
		});
	}

	@override
	void dispose() {
		_nameController.dispose();
		_phoneController.dispose();
		_phoneFocusNode.dispose();
		super.dispose();
	}

	Future<void> _pickDate() async {
		final pickedDate = await showDatePicker(
			context: context,
			initialDate: _selectedDate,
			firstDate: DateTime.now().subtract(const Duration(days: 30)),
			lastDate: DateTime.now().add(const Duration(days: 365)),
			builder: (context, child) {
				return Theme(
					data: Theme.of(context),
					child: child!,
				);
			},
		);

		if (pickedDate == null) {
			return;
		}

		setState(() => _selectedDate = pickedDate);
	}

	Future<void> _pickTime() async {
		final pickedTime = await showTimePicker(
			context: context,
			initialTime: _selectedTime,
			builder: (context, child) {
				return Theme(
					data: Theme.of(context),
					child: child!,
				);
			},
		);

		if (pickedTime == null) {
			return;
		}

		setState(() => _selectedTime = pickedTime);
	}

	void _save() async {
		_phoneFocusNode.unfocus();

		final clientName = _nameController.text.trim();
		final service = _selectedService;
		final phoneDigits = extractPhoneDigits(_phoneController.text);

		if (clientName.isEmpty) {
			setState(() => _errorText = 'Введите имя клиента');
			return;
		}

		if (!isPhoneComplete(_phoneController.text)) {
			setState(() => _errorText = 'Введите полный номер телефона');
			return;
		}

		if (service == null) {
			setState(() => _errorText = 'Выберите услугу');
			return;
		}

		final phoneChanged = phoneDigits != widget.appointment.clientPhoneDigits;
		var clientRating = widget.appointment.clientRating;
		var riskLevel = widget.appointment.riskLevel;
		var daysSinceVerified = widget.appointment.daysSinceVerified;

		if (phoneChanged) {
			final checkResult = await ClientProfileService.lookupByPhone(_phoneController.text);
			if (checkResult == null) {
				setState(() {
					_errorText = 'Клиент не найден в базе сообщества';
				});
				return;
			}

			clientRating = checkResult.profile.reviewsAverage;
			riskLevel = appointmentRiskLevelForRating(clientRating);
			daysSinceVerified = 0;
			ClientProfileService.cacheProfile(phoneDigits, checkResult.profile);
		}

		final scheduledAt = DateTime(
			_selectedDate.year,
			_selectedDate.month,
			_selectedDate.day,
			_selectedTime.hour,
			_selectedTime.minute,
		);

		final updatedAppointment = widget.appointment.copyWith(
			clientName: clientName,
			clientPhoneDigits: phoneDigits,
			serviceName: service.name,
			serviceDurationLabel: service.durationLabel,
			scheduledAt: scheduledAt,
			servicePrice: service.price,
			clientRating: clientRating,
			riskLevel: riskLevel,
			daysSinceVerified: daysSinceVerified,
		);

		await DashboardDataService.updateAppointment(updatedAppointment);
		Navigator.of(context).pop(phoneChanged);
	}

	@override
	Widget build(BuildContext context) {
		final service = _selectedService;
		final dateLabel = formatAppointmentDateLabel(_selectedDate);
		final timeLabel = formatAppointmentTimeLabel(
			DateTime(
				_selectedDate.year,
				_selectedDate.month,
				_selectedDate.day,
				_selectedTime.hour,
				_selectedTime.minute,
			),
		);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Редактировать запись',
						onBack: () => Navigator.of(context).pop(),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									_FormSection(
										title: 'Клиент',
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.stretch,
											children: [
												const _FieldLabel(label: 'Имя клиента'),
												const SizedBox(height: 8),
												TextField(
													controller: _nameController,
													style: const TextStyle(color: AppColors.textPrimary),
													decoration: _inputDecoration('Анна'),
												),
												const SizedBox(height: 16),
												const _FieldLabel(label: 'Телефон'),
												const SizedBox(height: 8),
												_PhoneField(
													controller: _phoneController,
													focusNode: _phoneFocusNode,
												),
											],
										),
									),
									const SizedBox(height: 12),
									_FormSection(
										title: 'Визит',
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.stretch,
											children: [
												const _FieldLabel(label: 'Дата'),
												const SizedBox(height: 8),
												_PickerTile(
													value: dateLabel,
													icon: Icons.calendar_today_outlined,
													onTap: _pickDate,
												),
												const SizedBox(height: 16),
												const _FieldLabel(label: 'Время'),
												const SizedBox(height: 8),
												_PickerTile(
													value: timeLabel,
													icon: Icons.schedule_outlined,
													onTap: _pickTime,
												),
												const SizedBox(height: 16),
												const _FieldLabel(label: 'Услуга'),
												const SizedBox(height: 8),
												if (_isLoadingServices)
													const Padding(
														padding: EdgeInsets.symmetric(vertical: 12),
														child: Center(child: CircularProgressIndicator()),
													)
												else
													DropdownButtonFormField<MasterService>(
														initialValue: service,
														decoration: _inputDecoration('Выберите услугу'),
														dropdownColor: AppColors.surfaceElevated,
														style: const TextStyle(
															color: AppColors.textPrimary,
															fontSize: 15,
														),
														items: _services.map((item) {
															return DropdownMenuItem(
																value: item,
																child: Text(
																	'${item.name} · ${item.durationLabel}',
																	overflow: TextOverflow.ellipsis,
																),
															);
														}).toList(),
														onChanged: (value) {
															setState(() => _selectedService = value);
														},
													),
											],
										),
									),
									if (_errorText != null) ...[
										const SizedBox(height: 12),
										Text(
											_errorText!,
											textAlign: TextAlign.center,
											style: const TextStyle(
												color: AppColors.error,
												fontSize: 13,
											),
										),
									],
								],
							),
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
						child: FilledButton(
							onPressed: _save,
							child: const Text('Сохранить изменения'),
						),
					),
				],
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
			padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
			child: Row(
				children: [
					IconButton(
						onPressed: onBack,
						icon: const Icon(
							Icons.arrow_back_ios_new_rounded,
							color: AppColors.textPrimary,
							size: 20,
						),
					),
					Expanded(
						child: Text(
							title,
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 18,
								fontWeight: FontWeight.w600,
							),
						),
					),
				],
			),
		);
	}
}

class _FormSection extends StatelessWidget {
	const _FormSection({
		required this.title,
		required this.child,
	});

	final String title;
	final Widget child;

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
							color: AppColors.textPrimary,
							fontSize: 16,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 16),
					child,
				],
			),
		);
	}
}

class _FieldLabel extends StatelessWidget {
	const _FieldLabel({required this.label});

	final String label;

	@override
	Widget build(BuildContext context) {
		return Text(
			label,
			style: const TextStyle(
				color: AppColors.textPrimary,
				fontSize: 14,
				fontWeight: FontWeight.w600,
			),
		);
	}
}

class _PhoneField extends StatelessWidget {
	const _PhoneField({
		required this.controller,
		required this.focusNode,
	});

	final TextEditingController controller;
	final FocusNode focusNode;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: AppColors.surfaceElevated,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				children: [
					const Padding(
						padding: EdgeInsets.only(left: 14),
						child: Text(
							'+7',
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 16,
								fontWeight: FontWeight.w500,
							),
						),
					),
					Expanded(
						child: TextField(
							controller: controller,
							focusNode: focusNode,
							keyboardType: TextInputType.phone,
							inputFormatters: [
								PhoneInputFormatter(),
							],
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 16,
							),
							decoration: const InputDecoration(
								hintText: '(999) 123-45-67',
								hintStyle: TextStyle(color: AppColors.textMuted),
								border: InputBorder.none,
								contentPadding: EdgeInsets.symmetric(
									horizontal: 8,
									vertical: 14,
								),
							),
						),
					),
				],
			),
		);
	}
}

class _PickerTile extends StatelessWidget {
	const _PickerTile({
		required this.value,
		required this.icon,
		required this.onTap,
	});

	final String value;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.surfaceElevated,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(12),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(12),
						border: Border.all(color: AppColors.border),
					),
					child: Row(
						children: [
							Icon(icon, color: AppColors.primary, size: 20),
							const SizedBox(width: 10),
							Expanded(
								child: Text(
									value,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 15,
									),
								),
							),
							const Icon(
								Icons.chevron_right_rounded,
								color: AppColors.textMuted,
								size: 20,
							),
						],
					),
				),
			),
		);
	}
}

InputDecoration _inputDecoration(String hintText) {
	return InputDecoration(
		hintText: hintText,
		hintStyle: const TextStyle(color: AppColors.textMuted),
		filled: true,
		fillColor: AppColors.surfaceElevated,
		contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
	);
}
