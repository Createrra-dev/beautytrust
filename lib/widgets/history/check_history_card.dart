import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/check_history_record.dart';
import '../../screens/appointments/appointment_detail_screen.dart';
import '../../services/dashboard_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';

class CheckHistoryCard extends StatelessWidget {
	const CheckHistoryCard({
		super.key,
		required this.record,
		this.referenceNow,
	});

	final CheckHistoryRecord record;
	final DateTime? referenceNow;

	@override
	Widget build(BuildContext context) {
		final ratingColor = appointmentRatingColor(record.rating);

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
						padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.center,
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										mainAxisSize: MainAxisSize.min,
										children: [
											Text(
												record.phone,
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style: const TextStyle(
													color: AppColors.textPrimary,
													fontSize: 15,
													fontWeight: FontWeight.w600,
													height: 1.2,
												),
											),
											const SizedBox(height: 6),
											Text(
												formatCheckPerformedAt(
													record.checkedAt,
													referenceNow: referenceNow,
												),
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style: const TextStyle(
													color: AppColors.textMuted,
													fontSize: 12,
													height: 1.2,
												),
											),
										],
									),
								),
								const SizedBox(width: 8),
								Column(
									crossAxisAlignment: CrossAxisAlignment.end,
									mainAxisSize: MainAxisSize.min,
									children: [
										Text(
											formatAppointmentRating(record.rating),
											style: TextStyle(
												color: ratingColor,
												fontSize: 22,
												fontWeight: FontWeight.w700,
												height: 1,
											),
										),
										const SizedBox(height: 4),
										Text(
											record.ratingLabel,
											style: TextStyle(
												color: ratingColor,
												fontSize: 13,
												fontWeight: FontWeight.w600,
												height: 1.2,
											),
										),
									],
								),
								const SizedBox(width: 4),
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
		final appointmentId = record.appointmentId;
		if (appointmentId == null) {
			AppSnackBar.show(
				context,
				record.clientName == null
					? 'Проверка: ${record.phone}'
					: '${record.clientName}: ${record.phone}',
			);
			return;
		}

		final appointment = DashboardDataService.appointmentById(appointmentId);
		if (appointment == null) {
			AppSnackBar.show(
				context,
				'Запись для этой проверки не найдена',
				type: AppSnackBarType.error,
			);
			return;
		}

		Navigator.of(context).pushNamed(
			AppointmentDetailScreen.routeName,
			arguments: appointment,
		);
	}
}
