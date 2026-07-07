import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
	const AppTextField({
		super.key,
		required this.label,
		this.controller,
		this.hintText,
		this.keyboardType,
		this.obscureText = false,
		this.inputFormatters,
		this.prefix,
		this.suffix,
		this.onChanged,
		this.errorText,
	});

	final String label;
	final TextEditingController? controller;
	final String? hintText;
	final TextInputType? keyboardType;
	final bool obscureText;
	final List<TextInputFormatter>? inputFormatters;
	final Widget? prefix;
	final Widget? suffix;
	final ValueChanged<String>? onChanged;
	final String? errorText;

	@override
	Widget build(BuildContext context) {
		final hasError = errorText != null;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					label,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 14,
					),
				),
				const SizedBox(height: 8),
				TextField(
					controller: controller,
					keyboardType: keyboardType,
					obscureText: obscureText,
					inputFormatters: inputFormatters,
					onChanged: onChanged,
					style: const TextStyle(
						color: AppColors.textPrimary,
						fontSize: 16,
					),
					decoration: InputDecoration(
						hintText: hintText,
						hintStyle: const TextStyle(color: AppColors.textMuted),
						filled: true,
						fillColor: AppColors.surface,
						contentPadding: const EdgeInsets.symmetric(
							horizontal: 16,
							vertical: 16,
						),
						border: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: BorderSide(
								color: hasError ? AppColors.error : AppColors.border,
							),
						),
						enabledBorder: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: BorderSide(
								color: hasError ? AppColors.error : AppColors.border,
							),
						),
						focusedBorder: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: BorderSide(
								color: hasError ? AppColors.error : AppColors.primary,
								width: 1.5,
							),
						),
						prefixIcon: prefix,
						suffixIcon: suffix,
					),
				),
				if (hasError) ...[
					const SizedBox(height: 8),
					Text(
						errorText!,
						style: const TextStyle(
							color: AppColors.error,
							fontSize: 13,
						),
					),
				],
			],
		);
	}
}
