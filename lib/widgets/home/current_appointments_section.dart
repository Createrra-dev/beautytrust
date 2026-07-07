import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../theme/app_theme.dart';

class CurrentAppointmentsSection extends StatelessWidget {
	const CurrentAppointmentsSection({
		super.key,
		required this.appointments,
	});

	final List<AppointmentRecord> appointments;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Row(
					children: [
						Expanded(
							child: Text(
								'Текущие записи',
								style: TextStyle(
									color: AppColors.textPrimary,
									fontSize: 18,
									fontWeight: FontWeight.w600,
								),
							),
						),
						Icon(
							Icons.chevron_right_rounded,
							color: AppColors.textMuted,
							size: 22,
						),
					],
				),
				const SizedBox(height: 12),
				...appointments.map(
					(appointment) => Padding(
						padding: const EdgeInsets.only(bottom: 10),
						child: _AppointmentCard(appointment: appointment),
					),
				),
			],
		);
	}
}

class _AppointmentCard extends StatelessWidget {
	const _AppointmentCard({required this.appointment});

	final AppointmentRecord appointment;

	@override
	Widget build(BuildContext context) {
		final statusColor = _statusColor(appointment.status);

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								appointment.timeLabel,
								style: const TextStyle(
									color: AppColors.textPrimary,
									fontSize: 16,
									fontWeight: FontWeight.w700,
								),
							),
							const SizedBox(height: 4),
							Text(
								appointment.dateLabel,
								style: const TextStyle(
									color: AppColors.textMuted,
									fontSize: 12,
								),
							),
						],
					),
					const SizedBox(width: 16),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									appointment.clientName,
									style: const TextStyle(
										color: AppColors.textPrimary,
										fontSize: 16,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 4),
								Text(
									appointment.serviceName,
									style: const TextStyle(
										color: AppColors.textMuted,
										fontSize: 14,
									),
								),
								const SizedBox(height: 10),
								Container(
									padding: const EdgeInsets.symmetric(
										horizontal: 10,
										vertical: 4,
									),
									decoration: BoxDecoration(
										color: statusColor.withValues(alpha: 0.12),
										borderRadius: BorderRadius.circular(8),
									),
									child: Text(
										appointment.statusLabel,
										style: TextStyle(
											color: statusColor,
											fontSize: 12,
											fontWeight: FontWeight.w600,
										),
									),
								),
							],
						),
					),
				],
			),
		);
	}

	Color _statusColor(AppointmentStatus status) {
		return switch (status) {
			AppointmentStatus.confirmed => AppColors.secondary,
			AppointmentStatus.pendingVerification => AppColors.primary,
			AppointmentStatus.atRisk => AppColors.error,
		};
	}
}
