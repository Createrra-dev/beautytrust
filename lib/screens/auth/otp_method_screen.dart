import 'package:flutter/material.dart';

import '../../models/otp_delivery_channel.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/auth/auth_scaffold.dart';
import 'otp_code_screen.dart';

class OtpMethodScreen extends StatelessWidget {
	const OtpMethodScreen({
		super.key,
		required this.phoneDigits,
		this.firstName,
		this.isRegistration = false,
	});

	final String phoneDigits;
	final String? firstName;
	final bool isRegistration;

	void _openOtpScreen(BuildContext context, OtpDeliveryChannel channel) {
		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => OtpCodeScreen(
					phoneDigits: phoneDigits,
					firstName: firstName,
					isRegistration: isRegistration,
					initialChannel: channel,
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final phone = formatPhoneDisplay(phoneDigits);

		return AuthScaffold(
			showBackButton: true,
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						const SizedBox(height: 8),
						const Text(
							'Подтверждение номера',
							textAlign: TextAlign.center,
							style: TextStyle(
								fontSize: 28,
								fontWeight: FontWeight.w700,
								color: AppColors.textPrimary,
							),
						),
						const SizedBox(height: 12),
						Text(
							isRegistration
								? 'Выберите способ подтверждения регистрации для номера $phone'
								: 'Выберите способ подтверждения входа для номера $phone',
							textAlign: TextAlign.center,
							style: const TextStyle(
								fontSize: 15,
								height: 1.4,
								color: AppColors.textMuted,
							),
						),
						const SizedBox(height: 32),
						_OtpMethodCard(
							icon: Icons.send_rounded,
							title: 'Telegram',
							description:
								'Код придёт в чат от бота Beauty Trust. Нужен установленный Telegram.',
							onTap: () => _openOtpScreen(context, OtpDeliveryChannel.telegram),
						),
						const SizedBox(height: 16),
						_OtpMethodCard(
							icon: Icons.phone_callback_rounded,
							title: 'Звонок',
							description:
								'Поступит входящий звонок. Введите последние 4 цифры номера звонящего.',
							onTap: () => _openOtpScreen(context, OtpDeliveryChannel.flashCall),
						),
					],
				),
			),
		);
	}
}

class _OtpMethodCard extends StatelessWidget {
	const _OtpMethodCard({
		required this.icon,
		required this.title,
		required this.description,
		required this.onTap,
	});

	final IconData icon;
	final String title;
	final String description;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.surface,
			borderRadius: BorderRadius.circular(16),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(16),
				child: Container(
					padding: const EdgeInsets.all(20),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: AppColors.border),
					),
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Container(
								width: 48,
								height: 48,
								decoration: BoxDecoration(
									color: AppColors.primary.withValues(alpha: 0.12),
									borderRadius: BorderRadius.circular(12),
								),
								child: Icon(
									icon,
									color: AppColors.primary,
								),
							),
							const SizedBox(width: 16),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											title,
											style: const TextStyle(
												fontSize: 18,
												fontWeight: FontWeight.w700,
												color: AppColors.textPrimary,
											),
										),
										const SizedBox(height: 8),
										Text(
											description,
											style: const TextStyle(
												fontSize: 14,
												height: 1.4,
												color: AppColors.textMuted,
											),
										),
									],
								),
							),
							const Icon(
								Icons.chevron_right_rounded,
								color: AppColors.textMuted,
							),
						],
					),
				),
			),
		);
	}
}
