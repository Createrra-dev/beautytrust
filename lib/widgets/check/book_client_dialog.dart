import 'package:flutter/material.dart';

import '../../data/master_services_data.dart';
import '../../models/appointment_record.dart';
import '../../models/client_check_result.dart';
import '../../models/master_service.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';

Future<bool> showBookClientDialog({
	required BuildContext context,
	required ClientCheckResult checkResult,
}) async {
	final booked = await showDialog<bool>(
		context: context,
		builder: (context) => _BookClientDialog(checkResult: checkResult),
	);

	return booked ?? false;
}

class _BookClientDialog extends StatefulWidget {
	const _BookClientDialog({required this.checkResult});

	final ClientCheckResult checkResult;

	@override
	State<_BookClientDialog> createState() => _BookClientDialogState();
}

class _BookClientDialogState extends State<_BookClientDialog> {
	final _nameController = TextEditingController();
	var _selectedDate = DateTime.now();
	var _selectedTime = TimeOfDay.now();
	MasterService? _selectedService;
	String? _errorText;

	@override
	void initState() {
		super.initState();
		_nameController.text = widget.checkResult.clientName;
		_selectedService = MasterServicesData.services.first;
	}

	@override
	void dispose() {
		_nameController.dispose();
		super.dispose();
	}

	Future<void> _pickDate() async {
		final pickedDate = await showDatePicker(
			context: context,
			initialDate: _selectedDate,
			firstDate: DateTime.now(),
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

	void _bookClient() {
		final clientName = _nameController.text.trim();
		final service = _selectedService;

		if (clientName.isEmpty) {
			setState(() => _errorText = 'Введите имя клиента');
			return;
		}

		if (service == null) {
			setState(() => _errorText = 'Выберите услугу');
			return;
		}

		final appointmentDate = DateTime(
			_selectedDate.year,
			_selectedDate.month,
			_selectedDate.day,
			_selectedTime.hour,
			_selectedTime.minute,
		);

		final profile = widget.checkResult.profile;
		final rating = profile.reviewsAverage;

		final phoneDigits = extractPhoneDigits(profile.phone);

		DashboardDataService.addAppointment(
			AppointmentRecord(
				id: DashboardDataService.nextAppointmentId(),
				clientName: clientName,
				clientPhoneDigits: phoneDigits,
				serviceName: service.name,
				serviceDurationLabel: service.durationLabel,
				scheduledAt: appointmentDate,
				servicePrice: service.price,
				clientRating: rating,
				riskLevel: appointmentRiskLevelForRating(rating),
				daysSinceVerified: 0,
			),
		);

		Navigator.of(context).pop(true);
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

		return AlertDialog(
			title: const Text('Записать клиента'),
			content: SingleChildScrollView(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						_DialogFieldLabel(label: 'Имя клиента'),
						const SizedBox(height: 8),
						TextField(
							controller: _nameController,
							style: const TextStyle(color: AppColors.textPrimary),
							decoration: _inputDecoration('Анна'),
						),
						const SizedBox(height: 16),
						_DialogFieldLabel(label: 'Дата записи'),
						const SizedBox(height: 8),
						_PickerTile(
							value: dateLabel,
							icon: Icons.calendar_today_outlined,
							onTap: _pickDate,
						),
						const SizedBox(height: 16),
						_DialogFieldLabel(label: 'Время записи'),
						const SizedBox(height: 8),
						_PickerTile(
							value: timeLabel,
							icon: Icons.schedule_outlined,
							onTap: _pickTime,
						),
						const SizedBox(height: 16),
						_DialogFieldLabel(label: 'Услуга'),
						const SizedBox(height: 8),
						DropdownButtonFormField<MasterService>(
							initialValue: service,
							decoration: _inputDecoration('Выберите услугу'),
							dropdownColor: AppColors.surfaceElevated,
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 15,
							),
							items: MasterServicesData.services.map((item) {
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
						if (_errorText != null) ...[
							const SizedBox(height: 12),
							Text(
								_errorText!,
								style: const TextStyle(
									color: AppColors.error,
									fontSize: 13,
								),
							),
						],
					],
				),
			),
			actions: [
				TextButton(
					onPressed: () => Navigator.of(context).pop(false),
					child: const Text('Отмена'),
				),
				FilledButton(
					onPressed: _bookClient,
					child: const Text('Записать'),
				),
			],
		);
	}
}

class _DialogFieldLabel extends StatelessWidget {
	const _DialogFieldLabel({required this.label});

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
