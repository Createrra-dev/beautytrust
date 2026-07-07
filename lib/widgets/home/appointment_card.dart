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
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				onTap: () => _openDetails(context),
				borderRadius: BorderRadius.circular(14),
				child: Ink(
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: AppColors.border),
					),
					child: Padding(
						padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.center,
							children: [
								_ScheduleColumn(
									timeLabel: appointment.timeLabel,
									dateLabel: appointment.dateLabel,
								),
								const SizedBox(width: 10),
								Expanded(
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											_CompactInfoRow(
												left: Text(
													appointment.clientName,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: const TextStyle(
														color: AppColors.textPrimary,
														fontSize: 15,
														fontWeight: FontWeight.w600,
														height: 1.2,
													),
												),
												right: _RatingBadge(
													rating: appointment.clientRating,
													color: ratingColor,
												),
											),
											const SizedBox(height: 4),
											_CompactInfoRow(
												left: Text(
													appointment.serviceName,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: const TextStyle(
														color: AppColors.textMuted,
														fontSize: 12,
														height: 1.2,
													),
												),
												right: _RiskBadge(
													label: appointment.riskLabel,
													color: riskColor,
												),
											),
											const SizedBox(height: 4),
											_CompactInfoRow(
												left: Text(
													appointment.priceLineLabel,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: const TextStyle(
														color: AppColors.textMuted,
														fontSize: 12,
														height: 1.2,
													),
												),
												right: Text(
													appointment.verifiedLabel,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													textAlign: TextAlign.right,
													style: const TextStyle(
														color: AppColors.textMuted,
														fontSize: 11,
														height: 1.2,
													),
												),
											),
										],
									),
								),
								const SizedBox(width: 2),
								const Icon(
									Icons.chevron_right_rounded,
									color: AppColors.textMuted,
									size: 18,
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
			width: 44,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisSize: MainAxisSize.min,
				children: [
					Text(
						timeLabel,
						style: const TextStyle(
							color: AppColors.primary,
							fontSize: 15,
							fontWeight: FontWeight.w700,
							height: 1.2,
						),
					),
					const SizedBox(height: 2),
					Text(
						dateLabel,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 11,
							height: 1.2,
						),
					),
				],
			),
		);
	}
}

class _CompactInfoRow extends StatelessWidget {
	const _CompactInfoRow({
		required this.left,
		required this.right,
	});

	final Widget left;
	final Widget right;

	@override
	Widget build(BuildContext context) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
				Expanded(child: left),
				const SizedBox(width: 8),
				Flexible(
					fit: FlexFit.loose,
					child: right,
				),
			],
		);
	}
}

class _RatingBadge extends StatelessWidget {
	const _RatingBadge({
		required this.rating,
		required this.color,
	});

	final double rating;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Row(
			mainAxisSize: MainAxisSize.min,
			children: [
				Icon(
					Icons.star_rounded,
					size: 14,
					color: color,
				),
				const SizedBox(width: 2),
				Text(
					formatAppointmentRating(rating),
					style: TextStyle(
						color: color,
						fontSize: 14,
						fontWeight: FontWeight.w700,
						height: 1.2,
					),
				),
			],
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
			padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: color.withValues(alpha: 0.55)),
			),
			child: Text(
				label,
				style: TextStyle(
					color: color,
					fontSize: 10,
					fontWeight: FontWeight.w600,
					height: 1.2,
				),
			),
		);
	}
}
