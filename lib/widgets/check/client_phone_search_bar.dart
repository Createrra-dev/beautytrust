import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';

class ClientPhoneSearchBar extends StatelessWidget {
	const ClientPhoneSearchBar({
		super.key,
		required this.controller,
		required this.focusNode,
		required this.onSearch,
	});

	final TextEditingController controller;
	final FocusNode focusNode;
	final VoidCallback onSearch;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.border),
			),
			child: Row(
				children: [
					const Padding(
						padding: EdgeInsets.only(left: 14),
						child: Text(
							'+7',
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 16,
								fontWeight: FontWeight.w500,
							),
						),
					),
					Expanded(
						child: TextField(
							controller: controller,
							focusNode: focusNode,
							keyboardType: TextInputType.phone,
							textInputAction: TextInputAction.search,
							inputFormatters: [
								PhoneInputFormatter(),
							],
							style: const TextStyle(
								color: AppColors.textPrimary,
								fontSize: 16,
							),
							decoration: const InputDecoration(
								hintText: '(999) 123-45-67',
								hintStyle: TextStyle(color: AppColors.textMuted),
								border: InputBorder.none,
								contentPadding: EdgeInsets.symmetric(
									horizontal: 8,
									vertical: 16,
								),
							),
							onSubmitted: (_) => onSearch(),
						),
					),
					Material(
						color: AppColors.primary,
						borderRadius: const BorderRadius.horizontal(
							right: Radius.circular(13),
						),
						child: InkWell(
							onTap: onSearch,
							borderRadius: const BorderRadius.horizontal(
								right: Radius.circular(13),
							),
							child: const SizedBox(
								width: 54,
								height: 54,
								child: Icon(
									Icons.search_rounded,
									color: AppColors.textPrimary,
								),
							),
						),
					),
				],
			),
		);
	}
}
