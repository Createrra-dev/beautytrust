import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PasswordRequirements extends StatelessWidget {
	const PasswordRequirements({
		super.key,
		required this.password,
	});

	final String password;

	@override
	Widget build(BuildContext context) {
		final requirements = [
			('Минимум 8 символов', password.length >= 8),
			('Хотя бы одна цифра', RegExp(r'\d').hasMatch(password)),
			('Хотя бы одна заглавная буква', RegExp(r'[A-ZА-Я]').hasMatch(password)),
		];

		return Column(
			children: requirements
				.map(
					(item) => Padding(
						padding: const EdgeInsets.only(bottom: 6),
						child: Row(
							children: [
								Icon(
									item.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
									size: 18,
									color: item.$2 ? AppColors.secondary : AppColors.textMuted,
								),
								const SizedBox(width: 8),
								Text(
									item.$1,
									style: TextStyle(
										color: item.$2 ? AppColors.secondary : AppColors.textMuted,
										fontSize: 13,
									),
								),
							],
						),
					),
				)
				.toList(),
		);
	}

	static bool isValid(String password) {
		return password.length >= 8 &&
			RegExp(r'\d').hasMatch(password) &&
			RegExp(r'[A-ZА-Я]').hasMatch(password);
	}
}
