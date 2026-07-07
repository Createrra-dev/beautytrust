import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/client_profile.dart';
import '../../models/visit_result.dart';
import '../../services/client_profile_service.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';

class VisitResultScreen extends StatefulWidget {
	const VisitResultScreen({
		super.key,
		required this.appointment,
	});

	final AppointmentRecord appointment;

	@override
	State<VisitResultScreen> createState() => _VisitResultScreenState();
}

class _VisitResultScreenState extends State<VisitResultScreen> {
	VisitPunctuality? _punctuality;
	bool? _paidInFull;
	bool? _hadScandal;
	bool? _leftTips;
	final _commentController = TextEditingController();
	String? _errorText;

	@override
	void initState() {
		super.initState();
		final initialResult = widget.appointment.visitResult;
		if (initialResult != null) {
			_punctuality = initialResult.punctuality;
			_paidInFull = initialResult.paidInFull;
			_hadScandal = initialResult.hadScandal;
			_leftTips = initialResult.leftTips;
			_commentController.text = initialResult.comment ?? '';
		}
	}

	@override
	void dispose() {
		_commentController.dispose();
		super.dispose();
	}

	void _save() async {
		final punctuality = _punctuality;
		final paidInFull = _paidInFull;
		final hadScandal = _hadScandal;
		final leftTips = _leftTips;

		if (punctuality == null) {
			setState(() => _errorText = 'Укажите, пришёл ли клиент вовремя');
			return;
		}

		if (punctuality != VisitPunctuality.noShow) {
			if (paidInFull == null) {
				setState(() => _errorText = 'Укажите, оплатил ли клиент полностью');
				return;
			}

			if (hadScandal == null) {
				setState(() => _errorText = 'Укажите, был ли скандал');
				return;
			}

			if (leftTips == null) {
				setState(() => _errorText = 'Укажите, оставил ли клиент чаевые');
				return;
			}
		}

		final comment = _commentController.text.trim();
		final visitResult = VisitResult(
			punctuality: punctuality,
			paidInFull: paidInFull ?? false,
			hadScandal: hadScandal ?? false,
			leftTips: leftTips ?? false,
			comment: comment.isEmpty ? null : comment,
		);

		await DashboardDataService.saveVisitResult(widget.appointment.id, visitResult);
		Navigator.of(context).pop(true);
	}

	@override
	Widget build(BuildContext context) {
		final appointment = widget.appointment;
		final profile = ClientProfileService.profileFor(appointment);
		final showVisitDetails = _punctuality != VisitPunctuality.noShow &&
			_punctuality != null;

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Результат визита',
						onBack: () => Navigator.of(context).pop(),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									_ClientSummaryCard(
										appointment: appointment,
										profile: profile,
									),
									const SizedBox(height: 16),
									_VisitQuestionCard(
										title: 'Пунктуальность',
										subtitle: 'Пришёл клиент вовремя?',
										child: _TripleChoiceRow(
											options: const [
												_VisitChoiceOption(
													label: 'Вовремя',
													value: VisitPunctuality.onTime,
												),
												_VisitChoiceOption(
													label: 'Опоздал',
													value: VisitPunctuality.late,
												),
												_VisitChoiceOption(
													label: 'Не пришёл',
													value: VisitPunctuality.noShow,
												),
											],
											selected: _punctuality,
											onChanged: (value) {
												setState(() {
													_punctuality = value;
													_errorText = null;
													if (value == VisitPunctuality.noShow) {
														_paidInFull = null;
														_hadScandal = null;
														_leftTips = null;
													}
												});
											},
										),
									),
									if (showVisitDetails) ...[
										const SizedBox(height: 12),
										_VisitQuestionCard(
											title: 'Оплата',
											subtitle: 'Клиент оплатил полностью?',
											child: _BinaryChoiceRow(
												firstLabel: 'Да',
												secondLabel: 'Нет',
												value: _paidInFull,
												onChanged: (value) {
													setState(() {
														_paidInFull = value;
														_errorText = null;
													});
												},
											),
										),
										const SizedBox(height: 12),
										_VisitQuestionCard(
											title: 'Поведение',
											subtitle: 'Был скандал во время визита?',
											child: _BinaryChoiceRow(
												firstLabel: 'Да',
												secondLabel: 'Нет',
												value: _hadScandal,
												onChanged: (value) {
													setState(() {
														_hadScandal = value;
														_errorText = null;
													});
												},
											),
										),
										const SizedBox(height: 12),
										_VisitQuestionCard(
											title: 'Чаевые',
											subtitle: 'Клиент оставил чаевые?',
											child: _BinaryChoiceRow(
												firstLabel: 'Да',
												secondLabel: 'Нет',
												value: _leftTips,
												onChanged: (value) {
													setState(() {
														_leftTips = value;
														_errorText = null;
													});
												},
											),
										),
									],
									const SizedBox(height: 12),
									_VisitQuestionCard(
										title: 'Комментарий',
										subtitle: 'Необязательно',
										child: TextField(
											controller: _commentController,
											minLines: 3,
											maxLines: 5,
											style: const TextStyle(color: AppColors.textPrimary),
											decoration: _inputDecoration('Дополнительные детали визита'),
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
							child: const Text('Сохранить результат'),
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

class _ClientSummaryCard extends StatelessWidget {
	const _ClientSummaryCard({
		required this.appointment,
		required this.profile,
	});

	final AppointmentRecord appointment;
	final ClientProfile profile;

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
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						appointment.clientName,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 18,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 4),
					Text(
						profile.phone,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 14,
						),
					),
					const SizedBox(height: 12),
					const Divider(color: AppColors.border, height: 1),
					const SizedBox(height: 12),
					Text(
						appointment.serviceName,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 15,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 6),
					Text(
						'${appointment.dateLabel}, ${appointment.timeLabel} · ${formatServicePrice(appointment.servicePrice)}',
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
						),
					),
				],
			),
		);
	}
}

class _VisitQuestionCard extends StatelessWidget {
	const _VisitQuestionCard({
		required this.title,
		required this.subtitle,
		required this.child,
	});

	final String title;
	final String subtitle;
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
					const SizedBox(height: 4),
					Text(
						subtitle,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
						),
					),
					const SizedBox(height: 12),
					child,
				],
			),
		);
	}
}

class _VisitChoiceOption<T> {
	const _VisitChoiceOption({
		required this.label,
		required this.value,
	});

	final String label;
	final T value;
}

class _TripleChoiceRow<T> extends StatelessWidget {
	const _TripleChoiceRow({
		required this.options,
		required this.selected,
		required this.onChanged,
	});

	final List<_VisitChoiceOption<T>> options;
	final T? selected;
	final ValueChanged<T> onChanged;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				for (var index = 0; index < options.length; index++) ...[
					if (index > 0) const SizedBox(width: 8),
					Expanded(
						child: _ChoiceChipButton(
							label: options[index].label,
							selected: selected == options[index].value,
							onTap: () => onChanged(options[index].value),
						),
					),
				],
			],
		);
	}
}

class _BinaryChoiceRow extends StatelessWidget {
	const _BinaryChoiceRow({
		required this.firstLabel,
		required this.secondLabel,
		required this.value,
		required this.onChanged,
	});

	final String firstLabel;
	final String secondLabel;
	final bool? value;
	final ValueChanged<bool> onChanged;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Expanded(
					child: _ChoiceChipButton(
						label: firstLabel,
						selected: value == true,
						onTap: () => onChanged(true),
					),
				),
				const SizedBox(width: 8),
				Expanded(
					child: _ChoiceChipButton(
						label: secondLabel,
						selected: value == false,
						onTap: () => onChanged(false),
					),
				),
			],
		);
	}
}

class _ChoiceChipButton extends StatelessWidget {
	const _ChoiceChipButton({
		required this.label,
		required this.selected,
		required this.onTap,
	});

	final String label;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: selected
				? AppColors.primary.withValues(alpha: 0.15)
				: AppColors.surfaceElevated,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(12),
				child: Container(
					padding: const EdgeInsets.symmetric(vertical: 12),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: selected ? AppColors.primary : AppColors.border,
						),
					),
					alignment: Alignment.center,
					child: Text(
						label,
						textAlign: TextAlign.center,
						style: TextStyle(
							color: selected ? AppColors.textPrimary : AppColors.textMuted,
							fontSize: 14,
							fontWeight: FontWeight.w600,
						),
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
