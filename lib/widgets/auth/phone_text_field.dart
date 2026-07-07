import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import 'app_text_field.dart';

class PhoneTextField extends StatelessWidget {
	const PhoneTextField({
		super.key,
		required this.controller,
	});

	final TextEditingController controller;

	static const String hintText = '( ___ ) ___ - __ - __';

	@override
	Widget build(BuildContext context) {
		return AppTextField(
			label: 'Номер телефона',
			controller: controller,
			keyboardType: TextInputType.phone,
			hintText: hintText,
			inputFormatters: [
				PhoneInputFormatter(),
			],
			prefix: const Padding(
				padding: EdgeInsets.only(left: 12, right: 4),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text('🇷🇺', style: TextStyle(fontSize: 18)),
						SizedBox(width: 8),
						Text(
							'+7',
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 16,
							),
						),
					],
				),
			),
		);
	}

	static void applyMaskToController(TextEditingController controller) {
		final digits = extractPhoneDigits(controller.text);
		if (digits.isEmpty) {
			return;
		}

		controller.text = formatPhoneInput(digits);
	}
}
