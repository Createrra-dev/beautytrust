import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../screens/appointments/appointments_list_screen.dart';
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
				Material(
					color: Colors.transparent,
					child: InkWell(
						onTap: () {
							Navigator.of(context).pushNamed(
								AppointmentsListScreen.routeName,
							);
						},
						borderRadius: BorderRadius.circular(8),
						child: const Padding(
							padding: EdgeInsets.symmetric(vertical: 2),
							child: Row(
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
						),
					),
				),
				const SizedBox(height: 12),
				if (appointments.isEmpty)
					const _EmptyActiveState()
				else
					...appointments.map(
						(appointment) => Padding(
							padding: const EdgeInsets.only(bottom: 8),
							child: AppointmentCard(appointment: appointment),
						),
					),
			],
		);
	}
}

class _EmptyActiveState extends StatelessWidget {
	const _EmptyActiveState();

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: const Text(
				'Нет активных записей',
				textAlign: TextAlign.center,
				style: TextStyle(
					color: AppColors.textMuted,
					fontSize: 14,
				),
			),
		);
	}
}
