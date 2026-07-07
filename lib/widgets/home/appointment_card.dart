import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../screens/appointments/appointment_detail_screen.dart';
import '../../theme/app_theme.dart';

class AppointmentCard extends StatelessWidget {
	const AppointmentCard({
		super.key,
		required this.appointment,
	});

	final AppointmentRecord appointment;

	@override
	Widget build(BuildContext context) {
		final ratingColor = appointmentRatingColor(appointment.clientRating);
		final riskColor = appointmentRiskColor(appointment.riskLevel);

		return Material(
			color: AppColors.surface,
			borderRadius: BorderRadius.circular(16),
			child: InkWell(
				onTap: () => _openDetails(context),
				borderRadius: BorderRadius.circular(16),
				child: Ink(
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: AppColors.border),
					),
					child: Padding(
						padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								_ScheduleColumn(
									timeLabel: appointment.timeLabel,
									dateLabel: appointment.dateLabel,
								),
								const SizedBox(width: 12),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
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
											const SizedBox(height: 6),
											Text(
												'${appointment.serviceName} · ${appointment.timeLabel} · ${formatServicePrice(appointment.servicePrice)}',
												maxLines: 2,
												overflow: TextOverflow.ellipsis,
												style: const TextStyle(
													color: AppColors.textMuted,
													fontSize: 13,
													height: 1.35,
												),
											),
										],
									),
								),
								const SizedBox(width: 8),
								Column(
									crossAxisAlignment: CrossAxisAlignment.end,
									children: [
										Text(
											formatAppointmentRating(appointment.clientRating),
											style: TextStyle(
												color: ratingColor,
												fontSize: 18,
												fontWeight: FontWeight.w700,
											),
										),
										const SizedBox(height: 8),
										_RiskBadge(
											label: appointment.riskLabel,
											color: riskColor,
										),
										const SizedBox(height: 6),
										Text(
											appointment.lastCheckedLabel,
											style: const TextStyle(
												color: AppColors.textMuted,
												fontSize: 11,
											),
										),
										const SizedBox(height: 8),
										const Icon(
											Icons.chevron_right_rounded,
											color: AppColors.textMuted,
											size: 20,
										),
									],
								),
							],
						),
					),
				),
			),
		);
	}

	void _openDetails(BuildContext context) {
		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => AppointmentDetailScreen(appointment: appointment),
			),
		);
	}
}

class _ScheduleColumn extends StatelessWidget {
	const _ScheduleColumn({
		required this.timeLabel,
		required this.dateLabel,
	});

	final String timeLabel;
	final String dateLabel;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: 52,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						timeLabel,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 16,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 4),
					Text(
						dateLabel,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 12,
						),
					),
				],
			),
		);
	}
}

class _RiskBadge extends StatelessWidget {
	const _RiskBadge({
		required this.label,
		required this.color,
	});

	final String label;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(8),
				border: Border.all(color: color.withValues(alpha: 0.35)),
			),
			child: Text(
				label,
				style: TextStyle(
					color: color,
					fontSize: 11,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}
