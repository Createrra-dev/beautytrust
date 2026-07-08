import 'package:flutter/services.dart';

String formatPhoneInput(String digits) {
	final limited = digits.length > 10 ? digits.substring(0, 10) : digits;

	final buffer = StringBuffer();
	if (limited.isNotEmpty) {
		buffer.write('(');
		buffer.write(limited.substring(0, limited.length >= 3 ? 3 : limited.length));
	}
	if (limited.length >= 3) {
		buffer.write(') ');
		buffer.write(
			limited.substring(3, limited.length >= 6 ? 6 : limited.length),
		);
	}
	if (limited.length >= 6) {
		buffer.write('-');
		buffer.write(
			limited.substring(6, limited.length >= 8 ? 8 : limited.length),
		);
	}
	if (limited.length >= 8) {
		buffer.write('-');
		buffer.write(limited.substring(8));
	}

	return buffer.toString();
}

class PhoneInputFormatter extends TextInputFormatter {
	static final RegExp _digitPattern = RegExp(r'\d');

	@override
	TextEditingValue formatEditUpdate(
		TextEditingValue oldValue,
		TextEditingValue newValue,
	) {
		final oldDigits = extractPhoneDigits(oldValue.text);
		var newDigits = extractPhoneDigits(newValue.text);

		final isDeleting = newValue.text.length < oldValue.text.length;
		if (isDeleting &&
			newDigits.length == oldDigits.length &&
			oldDigits.isNotEmpty) {
			newDigits = oldDigits.substring(0, oldDigits.length - 1);
		}

		if (newDigits.length > 10) {
			newDigits = newDigits.substring(0, 10);
		}

		final formatted = formatPhoneInput(newDigits);
		final selectionEnd = newValue.selection.end.clamp(0, newValue.text.length);
		final digitsBeforeCursor = extractPhoneDigits(
			newValue.text.substring(0, selectionEnd),
		).length;

		var cursorDigitIndex = digitsBeforeCursor.clamp(0, newDigits.length);
		if (isDeleting && newDigits.length < oldDigits.length) {
			cursorDigitIndex = newDigits.length;
		}

		return TextEditingValue(
			text: formatted,
			selection: TextSelection.collapsed(
				offset: _offsetForDigitIndex(formatted, cursorDigitIndex),
			),
		);
	}

	int _offsetForDigitIndex(String formatted, int digitIndex) {
		if (digitIndex <= 0) {
			return 0;
		}

		var seenDigits = 0;
		for (var index = 0; index < formatted.length; index++) {
			if (_digitPattern.hasMatch(formatted[index])) {
				seenDigits++;
				if (seenDigits == digitIndex) {
					return index + 1;
				}
			}
		}

		return formatted.length;
	}
}

String formatPhoneDisplay(String digits) {
	if (digits.length != 10) {
		return digits;
	}

	return '+7 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 8)}-${digits.substring(8)}';
}

String extractPhoneDigits(String value) {
	return value.replaceAll(RegExp(r'\D'), '');
}

String normalizePhoneDigits(String value) {
	var digits = extractPhoneDigits(value);
	if (digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))) {
		digits = digits.substring(1);
	}
	return digits;
}

bool isPhoneComplete(String value) {
	return normalizePhoneDigits(value).length == 10;
}
