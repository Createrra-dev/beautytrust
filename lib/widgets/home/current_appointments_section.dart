import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../theme/app_theme.dart';
import 'appointment_card.dart';

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
						child: AppointmentCard(appointment: appointment),
					),
				),
			],
		);
	}
}
