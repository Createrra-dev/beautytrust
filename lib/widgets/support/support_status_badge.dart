import 'package:flutter/material.dart';

import '../../models/support_ticket.dart';
import '../../theme/app_theme.dart';

class SupportStatusBadge extends StatelessWidget {
	const SupportStatusBadge({
		super.key,
		required this.status,
	});

	final SupportTicketStatus status;

	@override
	Widget build(BuildContext context) {
		final statusColor = status.color(
			AppColors.primary,
			AppColors.secondary,
			AppColors.textMuted,
			AppColors.error,
			AppColors.warning,
		);

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
			decoration: BoxDecoration(
				color: statusColor.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(20),
				border: Border.all(
					color: statusColor.withValues(alpha: 0.35),
				),
			),
			child: Text(
				status.label,
				style: TextStyle(
					color: statusColor,
					fontSize: 12,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}
