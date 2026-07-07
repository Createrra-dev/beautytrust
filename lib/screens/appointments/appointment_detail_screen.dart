import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_scaffold.dart';

class AppointmentDetailScreen extends StatelessWidget {
	const AppointmentDetailScreen({
		super.key,
		required this.appointment,
	});

	final AppointmentRecord appointment;

	@override
	Widget build(BuildContext context) {
		final ratingColor = appointmentRatingColor(appointment.clientRating);
		final riskColor = appointmentRiskColor(appointment.riskLevel);

		return AuthScaffold(
			showBackButton: true,
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const SizedBox(height: 8),
						Text(
							appointment.clientName,
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 28,
								fontWeight: FontWeight.w700,
							),
						),
						const SizedBox(height: 8),
						Text(
							'${appointment.dateLabel}, ${appointment.timeLabel}',
							style: const TextStyle(
								color: AppColors.textMuted,
								fontSize: 15,
							),
						),
						const SizedBox(height: 24),
						_buildInfoRow('Услуга', appointment.serviceName),
						const SizedBox(height: 12),
						_buildInfoRow('Стоимость', formatServicePrice(appointment.servicePrice)),
						const SizedBox(height: 12),
						_buildInfoRow(
							'Рейтинг клиента',
							formatAppointmentRating(appointment.clientRating),
							valueColor: ratingColor,
						),
						const SizedBox(height: 12),
						_buildInfoRow(
							'Риск неявки',
							appointment.riskLabel,
							valueColor: riskColor,
						),
						const SizedBox(height: 12),
						_buildInfoRow('Последняя проверка', appointment.lastCheckedLabel),
					],
				),
			),
		);
	}

	Widget _buildInfoRow(
		String label,
		String value, {
		Color? valueColor,
	}) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						label,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 13,
						),
					),
					const SizedBox(height: 6),
					Text(
						value,
						style: TextStyle(
							color: valueColor ?? AppColors.textPrimary,
							fontSize: 16,
							fontWeight: FontWeight.w600,
						),
					),
				],
			),
		);
	}
}
