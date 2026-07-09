import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/client_profile.dart';
import '../../models/visit_result.dart';
import '../../navigation/main_shell_navigation.dart';
import '../../services/api/app_api_repository.dart';
import '../../services/client_profile_service.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';

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
	final _api = AppApiRepository();
	VisitPunctuality? _punctuality;
	bool? _paidInFull;
	bool? _hadBehaviorIssues;
	bool _wasUnfriendly = false;
	bool _hadScandal = false;
	bool _threatenedComplaints = false;
	bool _demandedDiscount = false;
	bool _stoleFromSalon = false;
	bool? _leftTips;
	final _commentController = TextEditingController();
	String? _errorText;
	var _isSaving = false;
	var _isLoading = true;
	var _useDefaults = true;

	double? get _previewRating {
		return calculateVisitResultRating(
			punctuality: _punctuality,
			paidInFull: _paidInFull,
			hadBehaviorIssues: _hadBehaviorIssues,
			wasUnfriendly: _wasUnfriendly,
			hadScandal: _hadScandal,
			threatenedComplaints: _threatenedComplaints,
			demandedDiscount: _demandedDiscount,
			stoleFromSalon: _stoleFromSalon,
			leftTips: _leftTips,
		);
	}

	@override
	void initState() {
		super.initState();
		_bootstrap();
	}

	Future<void> _bootstrap() async {
		final initialResult = widget.appointment.visitResult;
		if (initialResult != null) {
			_applyVisitResult(initialResult);
			if (mounted) {
				setState(() => _isLoading = false);
			}
			return;
		}

		var useDefaults = true;
		try {
			final settings = await _api.fetchProfileSettings();
			useDefaults = settings.visitResultDefaultsEnabled;
		} catch (_) {
			useDefaults = true;
		}

		if (!mounted) {
			return;
		}

		setState(() {
			_useDefaults = useDefaults;
			if (useDefaults) {
				_applyVisitResult(VisitResult.defaults());
			}
			_isLoading = false;
		});
	}

	void _applyVisitResult(VisitResult result) {
		_punctuality = result.punctuality;
		_paidInFull = result.paidInFull;
		_hadBehaviorIssues = result.hadBehaviorIssues;
		_wasUnfriendly = result.wasUnfriendly;
		_hadScandal = result.hadScandal;
		_threatenedComplaints = result.threatenedComplaints;
		_demandedDiscount = result.demandedDiscount;
		_stoleFromSalon = result.stoleFromSalon;
		_leftTips = result.leftTips;
		_commentController.text = result.comment ?? '';
	}

	void _applyDefaultVisitDetails() {
		final defaults = VisitResult.defaults();
		_paidInFull = defaults.paidInFull;
		_hadBehaviorIssues = defaults.hadBehaviorIssues;
		_leftTips = defaults.leftTips;
		_clearBehaviorDetails();
	}

	void _clearVisitDetails() {
		if (_useDefaults) {
			_applyDefaultVisitDetails();
			return;
		}

		_paidInFull = null;
		_hadBehaviorIssues = null;
		_leftTips = null;
		_clearBehaviorDetails();
	}

	void _clearBehaviorDetails() {
		_wasUnfriendly = false;
		_hadScandal = false;
		_threatenedComplaints = false;
		_demandedDiscount = false;
		_stoleFromSalon = false;
	}

	@override
	void dispose() {
		_commentController.dispose();
		super.dispose();
	}

	void _save() async {
		if (_isSaving) {
			return;
		}

		final punctuality = _punctuality;
		if (punctuality == null) {
			setState(() => _errorText = 'Укажите, пришёл ли клиент вовремя');
			return;
		}

		if (punctuality != VisitPunctuality.noShow) {
			if (_paidInFull == null) {
				setState(() => _errorText = 'Укажите, оплатил ли клиент полностью');
				return;
			}

			if (_hadBehaviorIssues == null) {
				setState(() => _errorText = 'Укажите, были ли проблемы с поведением');
				return;
			}

			if (_leftTips == null) {
				setState(() => _errorText = 'Укажите, оставил ли клиент чаевые');
				return;
			}
		}

		final comment = _commentController.text.trim();
		final hadBehaviorIssues =
			punctuality != VisitPunctuality.noShow && (_hadBehaviorIssues ?? false);
		final visitResult = VisitResult(
			punctuality: punctuality,
			paidInFull: punctuality == VisitPunctuality.noShow ? false : _paidInFull!,
			hadBehaviorIssues: hadBehaviorIssues,
			wasUnfriendly: hadBehaviorIssues && _wasUnfriendly,
			hadScandal: hadBehaviorIssues && _hadScandal,
			threatenedComplaints: hadBehaviorIssues && _threatenedComplaints,
			demandedDiscount: hadBehaviorIssues && _demandedDiscount,
			stoleFromSalon: hadBehaviorIssues && _stoleFromSalon,
			leftTips: punctuality == VisitPunctuality.noShow ? false : _leftTips!,
			comment: comment.isEmpty ? null : comment,
		);

		setState(() => _isSaving = true);

		try {
			await DashboardDataService.saveVisitResult(
				widget.appointment.id,
				visitResult,
			);
			if (!mounted) {
				return;
			}

			final messenger = ScaffoldMessenger.of(context);
			MainShellNavigation.instance.goToHome();
			Navigator.of(context).popUntil((route) => route.isFirst);
			messenger.hideCurrentSnackBar();
			messenger.showSnackBar(
				SnackBar(
					behavior: SnackBarBehavior.floating,
					backgroundColor: Colors.transparent,
					elevation: 0,
					margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
					padding: EdgeInsets.zero,
					content: Container(
						padding: const EdgeInsets.symmetric(
							horizontal: 14,
							vertical: 12,
						),
						decoration: BoxDecoration(
							color: AppColors.surfaceElevated,
							borderRadius: BorderRadius.circular(12),
							border: Border.all(
								color: AppColors.secondary.withValues(alpha: 0.45),
							),
						),
						child: const Row(
							children: [
								Icon(
									Icons.check_circle_outline_rounded,
									color: AppColors.secondary,
									size: 20,
								),
								SizedBox(width: 10),
								Expanded(
									child: Text(
										'Результат визита сохранён',
										style: TextStyle(
											color: AppColors.textPrimary,
											fontSize: 14,
											fontWeight: FontWeight.w500,
											height: 1.35,
										),
									),
								),
							],
						),
					),
				),
			);
		} catch (error) {
			if (!mounted) {
				return;
			}
			setState(() => _isSaving = false);
			AppSnackBar.show(
				context,
				'Не удалось сохранить результат визита',
				type: AppSnackBarType.error,
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final appointment = widget.appointment;
		final profile = ClientProfileService.profileFor(appointment);
		final showVisitDetails = _punctuality != null &&
			_punctuality != VisitPunctuality.noShow;
		final showBehaviorDetails = showVisitDetails && (_hadBehaviorIssues ?? false);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Результат визита',
						onBack: () => Navigator.of(context).pop(),
					),
					Expanded(
						child: _isLoading
							? const Center(child: CircularProgressIndicator())
							: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									_ClientSummaryCard(
										appointment: appointment,
										profile: profile,
									),
									const SizedBox(height: 12),
									_VisitRatingCard(rating: _previewRating),
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
													final wasNoShow =
														_punctuality == VisitPunctuality.noShow;
													_punctuality = value;
													_errorText = null;
													if (value == VisitPunctuality.noShow) {
														_clearVisitDetails();
													} else if (wasNoShow &&
														_useDefaults &&
														_paidInFull == null) {
														_applyDefaultVisitDetails();
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
											subtitle: 'Были проблемы с поведением?',
											child: _BinaryChoiceRow(
												firstLabel: 'Да',
												secondLabel: 'Нет',
												value: _hadBehaviorIssues,
												onChanged: (value) {
													setState(() {
														_hadBehaviorIssues = value;
														_errorText = null;
														if (!value) {
															_clearBehaviorDetails();
														}
													});
												},
											),
										),
										if (showBehaviorDetails) ...[
											const SizedBox(height: 12),
											_VisitQuestionCard(
												title: 'Что произошло',
												subtitle: 'Можно выбрать несколько пунктов',
												child: Wrap(
													spacing: 8,
													runSpacing: 8,
													children: [
														_BehaviorToggleChip(
															label: 'Не дружелюбен',
															selected: _wasUnfriendly,
															onTap: () {
																setState(() {
																	_wasUnfriendly = !_wasUnfriendly;
																	_errorText = null;
																});
															},
														),
														_BehaviorToggleChip(
															label: 'Скандал',
															selected: _hadScandal,
															onTap: () {
																setState(() {
																	_hadScandal = !_hadScandal;
																	_errorText = null;
																});
															},
														),
														_BehaviorToggleChip(
															label: 'Угрозы / жалобы',
															selected: _threatenedComplaints,
															onTap: () {
																setState(() {
																	_threatenedComplaints = !_threatenedComplaints;
																	_errorText = null;
																});
															},
														),
														_BehaviorToggleChip(
															label: 'Требовал скидку',
															selected: _demandedDiscount,
															onTap: () {
																setState(() {
																	_demandedDiscount = !_demandedDiscount;
																	_errorText = null;
																});
															},
														),
														_BehaviorToggleChip(
															label: 'Что-то украл',
															selected: _stoleFromSalon,
															onTap: () {
																setState(() {
																	_stoleFromSalon = !_stoleFromSalon;
																	_errorText = null;
																});
															},
														),
													],
												),
											),
										],
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
							onPressed: _isSaving ? null : _save,
							child: _isSaving
								? const SizedBox(
									width: 22,
									height: 22,
									child: CircularProgressIndicator(
										strokeWidth: 2,
										color: AppColors.textPrimary,
									),
								)
								: const Text('Сохранить результат'),
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

class _VisitRatingCard extends StatelessWidget {
	const _VisitRatingCard({required this.rating});

	final double? rating;

	@override
	Widget build(BuildContext context) {
		if (rating == null) {
			return Container(
				padding: const EdgeInsets.all(16),
				decoration: BoxDecoration(
					color: AppColors.surface,
					borderRadius: BorderRadius.circular(16),
					border: Border.all(color: AppColors.border),
				),
				child: const Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							'Оценка визита',
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 16,
								fontWeight: FontWeight.w700,
							),
						),
						SizedBox(height: 6),
						Text(
							'Ответьте на вопросы — оценка появится автоматически',
							style: TextStyle(
								color: AppColors.textMuted,
								fontSize: 13,
							),
						),
					],
				),
			);
		}

		final ratingColor = appointmentRatingColor(rating!);
		final ratingLabel = appointmentRatingLabel(rating!);

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: ratingColor.withValues(alpha: 0.45)),
			),
			child: Row(
				children: [
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Оценка визита',
									style: TextStyle(
										color: AppColors.textMuted,
										fontSize: 13,
									),
								),
								const SizedBox(height: 4),
								Text(
									ratingLabel,
									style: TextStyle(
										color: ratingColor,
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
							],
						),
					),
					Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(
								Icons.star_rounded,
								color: ratingColor,
								size: 28,
							),
							const SizedBox(width: 4),
							Text(
								formatAppointmentRating(rating!),
								style: TextStyle(
									color: ratingColor,
									fontSize: 32,
									fontWeight: FontWeight.w700,
									height: 1,
								),
							),
							const SizedBox(width: 4),
							Text(
								'/ 5',
								style: TextStyle(
									color: ratingColor.withValues(alpha: 0.75),
									fontSize: 16,
									fontWeight: FontWeight.w600,
								),
							),
						],
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

class _BehaviorToggleChip extends StatelessWidget {
	const _BehaviorToggleChip({
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
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: selected ? AppColors.primary : AppColors.border,
						),
					),
					child: Text(
						label,
						style: TextStyle(
							color: selected ? AppColors.textPrimary : AppColors.textMuted,
							fontSize: 13,
							fontWeight: FontWeight.w600,
						),
					),
				),
			),
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
