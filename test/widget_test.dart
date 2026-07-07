import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tbank_payment_test/main.dart';
import 'package:tbank_payment_test/screens/auth/phone_login_screen.dart';

void main() {
	testWidgets('App starts with phone login screen', (WidgetTester tester) async {
		await tester.pumpWidget(const BeautyTrustApp());

		expect(find.text('Вход по телефону'), findsOneWidget);
		expect(find.text('Продолжить'), findsOneWidget);
		expect(find.text('Зарегистрироваться'), findsOneWidget);
		expect(find.byType(PhoneLoginScreen), findsOneWidget);
	});

	testWidgets('Continue button enables after full phone input', (WidgetTester tester) async {
		await tester.pumpWidget(
			const MaterialApp(home: PhoneLoginScreen()),
		);

		final continueButton = find.widgetWithText(FilledButton, 'Продолжить');
		expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

		await tester.enterText(find.byType(TextField), '9991234567');
		await tester.pump();

		expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
	});
}
