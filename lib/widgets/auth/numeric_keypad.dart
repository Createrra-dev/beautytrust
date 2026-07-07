import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum NumericKeypadStyle {
	plain,
	plated,
}

class NumericKeypad extends StatelessWidget {
	const NumericKeypad({
		super.key,
		required this.onDigit,
		required this.onBackspace,
		this.style = NumericKeypadStyle.plain,
	});

	final ValueChanged<String> onDigit;
	final VoidCallback onBackspace;
	final NumericKeypadStyle style;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
			child: Column(
				children: [
					_buildRow(['1', '2', '3']),
					_buildRow(['4', '5', '6']),
					_buildRow(['7', '8', '9']),
					Row(
						children: [
							const Expanded(child: SizedBox()),
							Expanded(child: _KeyButton(label: '0', onTap: () => onDigit('0'), style: style)),
							Expanded(
								child: _KeyButton(
									icon: Icons.backspace_outlined,
									onTap: onBackspace,
									style: style,
									showPlate: false,
								),
							),
						],
					),
				],
			),
		);
	}

	Widget _buildRow(List<String> digits) {
		return Row(
			children: digits
				.map(
					(digit) => Expanded(
						child: _KeyButton(
							label: digit,
							onTap: () => onDigit(digit),
							style: style,
						),
					),
				)
				.toList(),
		);
	}
}

class _KeyButton extends StatelessWidget {
	const _KeyButton({
		this.label,
		this.icon,
		required this.onTap,
		required this.style,
		this.showPlate = true,
	});

	final String? label;
	final IconData? icon;
	final VoidCallback onTap;
	final NumericKeypadStyle style;
	final bool showPlate;

	bool get _usePlate => style == NumericKeypadStyle.plated && showPlate && label != null;

	@override
	Widget build(BuildContext context) {
		final content = icon != null
			? Icon(icon, color: AppColors.textPrimary, size: 26)
			: Text(
				label!,
				style: TextStyle(
					color: AppColors.textPrimary,
					fontSize: _usePlate ? 28 : 32,
					fontWeight: _usePlate ? FontWeight.w400 : FontWeight.w300,
					height: 1,
				),
			);

		return Padding(
			padding: const EdgeInsets.all(6),
			child: GestureDetector(
				onTap: onTap,
				behavior: HitTestBehavior.opaque,
				child: _usePlate
					? Container(
						height: 56,
						alignment: Alignment.center,
						decoration: BoxDecoration(
							color: AppColors.keypadPlate,
							borderRadius: BorderRadius.circular(14),
						),
						child: content,
					)
					: SizedBox(
						height: 72,
						child: Center(child: content),
					),
			),
		);
	}
}
