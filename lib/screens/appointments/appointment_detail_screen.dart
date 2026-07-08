import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/client_profile.dart';
import '../../services/client_profile_service.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/reviews/master_review_card.dart';
import 'visit_result_screen.dart';
import 'edit_appointment_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
	const AppointmentDetailScreen({
		super.key,
		required this.appointment,
	});

	static const routeName = '/appointment-detail';

	final AppointmentRecord appointment;

	@override
	State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
	final _dashboardService = DashboardDataService.instance;

	@override
	void initState() {
		super.initState();
		_dashboardService.addListener(_onDashboardChanged);
	}

	@override
	void dispose() {
		_dashboardService.removeListener(_onDashboardChanged);
		super.dispose();
	}

	void _onDashboardChanged() {
		setState(() {});
	}

	AppointmentRecord get _appointment {
		return DashboardDataService.appointmentById(widget.appointment.id) ??
			widget.appointment;
	}

	Future<void> _openVisitResultScreen() async {
		final saved = await Navigator.of(context).push<bool>(
			MaterialPageRoute(
				builder: (context) => VisitResultScreen(appointment: _appointment),
			),
		);

		if (!mounted || saved != true) {
			return;
		}

		AppSnackBar.show(
			context,
			'Результат визита сохранён',
			type: AppSnackBarType.success,
		);
	}

	Future<void> _openEditScreen() async {
		final phoneChanged = await Navigator.of(context).push<bool>(
			MaterialPageRoute(
				builder: (context) => EditAppointmentScreen(appointment: _appointment),
			),
		);

		if (!mounted || phoneChanged == null) {
			return;
		}

		AppSnackBar.show(
			context,
			phoneChanged
				? 'Запись обновлена, рейтинг клиента пересчитан'
				: 'Запись обновлена',
			type: AppSnackBarType.success,
		);
	}

	Future<void> _confirmDelete() async {
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Удалить запись?'),
					content: const Text('Запись будет удалена без возможности восстановления.'),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Отмена'),
						),
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							child: const Text('Удалить'),
						),
					],
				);
			},
		);

		if (confirmed != true || !mounted) {
			return;
		}

		try {
			await DashboardDataService.deleteAppointment(_appointment.id);
			if (!mounted) {
				return;
			}
			Navigator.of(context).pop();
			AppSnackBar.show(
				context,
				'Запись удалена',
				type: AppSnackBarType.success,
			);
		} catch (error) {
			if (!mounted) {
				return;
			}
			AppSnackBar.show(
				context,
				error.toString(),
				type: AppSnackBarType.error,
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final appointment = _appointment;
		final profile = ClientProfileService.profileFor(appointment);
		final ratingColor = appointmentRatingColor(profile.reviewsAverage);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					_PageHeader(
						title: 'Детали записи',
						onBack: () => Navigator.of(context).pop(),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								_ClientDataCard(
									appointment: appointment,
									profile: profile,
									ratingColor: ratingColor,
								),
								const SizedBox(height: 12),
								_AppointmentDetailsCard(
									appointment: appointment,
									onEdit: _openEditScreen,
									onDelete: _confirmDelete,
									onVisitResult: _openVisitResultScreen,
								),
							],
						),
					),
					const SizedBox(height: 12),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
							child: Container(
								padding: const EdgeInsets.all(16),
								decoration: BoxDecoration(
									color: AppColors.surface,
									borderRadius: BorderRadius.circular(16),
									border: Border.all(color: AppColors.border),
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										_ReviewsSection(reviews: profile.reviews),
										const SizedBox(height: 16),
										_ReliabilityBanner(
											profile: profile,
											ratingColor: ratingColor,
										),
									],
								),
							),
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

class _ClientDataCard extends StatelessWidget {
	const _ClientDataCard({
		required this.appointment,
		required this.profile,
		required this.ratingColor,
	});

	final AppointmentRecord appointment;
	final ClientProfile profile;
	final Color ratingColor;

	@override
	Widget build(BuildContext context) {
		final initials = _initials(appointment.clientName);

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
					Row(
						crossAxisAlignment: CrossAxisAlignment.center,
						children: [
							Container(
								decoration: BoxDecoration(
									shape: BoxShape.circle,
									border: Border.all(
										color: AppColors.border,
										width: 1.5,
									),
								),
								child: CircleAvatar(
									radius: 26,
									backgroundColor: AppColors.surfaceElevated,
									child: Text(
										initials,
										style: const TextStyle(
											color: AppColors.textPrimary,
											fontSize: 17,
											fontWeight: FontWeight.w600,
										),
									),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisSize: MainAxisSize.min,
									children: [
										Text(
											appointment.clientName,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: const TextStyle(
												color: AppColors.textPrimary,
												fontSize: 16,
												fontWeight: FontWeight.w600,
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
									],
								),
							),
							const SizedBox(width: 8),
							ReviewRatingBadge(
								rating: profile.reviewsAverage,
								label: profile.ratingLabel,
								ratingFontSize: 24,
								labelFontSize: 11,
							),
						],
					),
					const SizedBox(height: 14),
					const Divider(color: AppColors.border, height: 1),
					const SizedBox(height: 14),
					_StatsRow(profile: profile, ratingColor: ratingColor),
				],
			),
		);
	}

	String _initials(String name) {
		final parts = name.trim().split(RegExp(r'\s+'));
		if (parts.length == 1) {
			return parts.first.substring(0, 1).toUpperCase();
		}

		return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
	}
}

class _AppointmentDetailsCard extends StatelessWidget {
	const _AppointmentDetailsCard({
		required this.appointment,
		required this.onEdit,
		required this.onDelete,
		required this.onVisitResult,
	});

	final AppointmentRecord appointment;
	final VoidCallback onEdit;
	final VoidCallback onDelete;
	final VoidCallback onVisitResult;

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
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Icon(
								Icons.calendar_today_outlined,
								size: 16,
								color: AppColors.primary,
							),
							const SizedBox(width: 8),
							Expanded(
								child: Text(
									'${appointment.dateLabel}, ${appointment.timeLabel}',
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
							),
							_AppointmentActionIconButton(
								icon: Icons.edit_outlined,
								color: AppColors.primary,
								onPressed: onEdit,
							),
							_AppointmentActionIconButton(
								icon: Icons.delete_outline,
								color: AppColors.error,
								onPressed: onDelete,
							),
						],
					),
					const SizedBox(height: 12),
					Text(
						appointment.serviceName,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 16,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 6),
					Text(
						'Длительность: ${appointment.serviceDurationLabel} · ${formatServicePrice(appointment.servicePrice)}',
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
						),
					),
					const SizedBox(height: 14),
					FilledButton.icon(
						onPressed: onVisitResult,
						icon: const Icon(Icons.fact_check_outlined, size: 20),
						label: const Text('Результат визита'),
					),
				],
			),
		);
	}
}

class _AppointmentActionIconButton extends StatelessWidget {
	const _AppointmentActionIconButton({
		required this.icon,
		required this.color,
		required this.onPressed,
	});

	final IconData icon;
	final Color color;
	final VoidCallback onPressed;

	@override
	Widget build(BuildContext context) {
		return IconButton(
			onPressed: onPressed,
			padding: EdgeInsets.zero,
			visualDensity: VisualDensity.compact,
			constraints: const BoxConstraints(
				minWidth: 32,
				minHeight: 32,
			),
			icon: Icon(
				icon,
				size: 20,
				color: color,
			),
		);
	}
}

class _StatsRow extends StatelessWidget {
	const _StatsRow({
		required this.profile,
		required this.ratingColor,
	});

	final ClientProfile profile;
	final Color ratingColor;

	@override
	Widget build(BuildContext context) {
		return IntrinsicHeight(
			child: Row(
				children: [
					Expanded(
						child: _StatTile(
							title: 'Отзывы мастеров',
							icon: Icons.star_rounded,
							iconColor: ratingColor,
							value: '${formatAppointmentRating(profile.reviewsAverage)}/5',
							subtitle: '${profile.reviewsCount} отзыва',
						),
					),
					const _VerticalDivider(),
					Expanded(
						child: _StatTile(
							title: 'Неявки',
							icon: Icons.event_busy_outlined,
							iconColor: AppColors.primary,
							value: '${profile.noShowsCount}',
							subtitle: 'за 6 мес.',
						),
					),
					const _VerticalDivider(),
					Expanded(
						child: _StatTile(
							title: 'Скандалы',
							icon: Icons.star_outline_rounded,
							iconColor: AppColors.primary,
							value: '${profile.scandalsCount}',
							subtitle: 'за 6 мес.',
						),
					),
				],
			),
		);
	}
}

class _VerticalDivider extends StatelessWidget {
	const _VerticalDivider();

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 1,
			margin: const EdgeInsets.symmetric(horizontal: 8),
			color: AppColors.border,
		);
	}
}

class _StatTile extends StatelessWidget {
	const _StatTile({
		required this.title,
		required this.icon,
		required this.iconColor,
		required this.value,
		required this.subtitle,
	});

	final String title;
	final IconData icon;
	final Color iconColor;
	final String value;
	final String subtitle;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					title,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 11,
						height: 1.2,
					),
				),
				const SizedBox(height: 8),
				Row(
					children: [
						Icon(icon, size: 16, color: iconColor),
						const SizedBox(width: 4),
						Flexible(
							child: Text(
								value,
								style: const TextStyle(
									color: AppColors.textPrimary,
									fontSize: 15,
									fontWeight: FontWeight.w700,
								),
							),
						),
					],
				),
				const SizedBox(height: 4),
				Text(
					subtitle,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 11,
					),
				),
			],
		);
	}
}

class _ReviewsSection extends StatelessWidget {
	const _ReviewsSection({required this.reviews});

	final List<MasterReview> reviews;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Row(
					children: [
						Expanded(
							child: Text(
								'Что говорят мастера',
								style: TextStyle(
									color: AppColors.textPrimary,
									fontSize: 16,
									fontWeight: FontWeight.w600,
								),
							),
						),
						Text(
							'Смотреть все',
							style: TextStyle(
								color: AppColors.primary,
								fontSize: 13,
								fontWeight: FontWeight.w600,
							),
						),
					],
				),
				const SizedBox(height: 12),
				...reviews.map(
					(review) => Padding(
						padding: const EdgeInsets.only(bottom: 8),
						child: MasterReviewCard(review: review),
					),
				),
			],
		);
	}
}

class _ReliabilityBanner extends StatelessWidget {
	const _ReliabilityBanner({
		required this.profile,
		required this.ratingColor,
	});

	final ClientProfile profile;
	final Color ratingColor;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: ratingColor.withValues(alpha: 0.08),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: ratingColor.withValues(alpha: 0.25)),
			),
			child: Row(
				children: [
					Icon(
						Icons.verified_user_outlined,
						color: ratingColor,
						size: 22,
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									profile.reliabilityTitle,
									style: TextStyle(
										color: ratingColor,
										fontSize: 14,
										fontWeight: FontWeight.w700,
									),
								),
								const SizedBox(height: 2),
								Text(
									profile.reliabilitySubtitle,
									style: const TextStyle(
										color: AppColors.textMuted,
										fontSize: 12,
									),
								),
							],
						),
					),
				],
			),
		);
	}
}
