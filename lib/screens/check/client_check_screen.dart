import 'package:flutter/material.dart';

import '../../models/client_check_result.dart';
import '../../navigation/main_shell_navigation.dart';
import '../../services/client_check_flow_service.dart';
import '../../services/client_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/brand_title.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/check/book_client_dialog.dart';
import '../../widgets/check/client_check_result_panel.dart';
import '../../widgets/check/client_phone_search_bar.dart';
import 'how_it_works_screen.dart';

class ClientCheckScreen extends StatefulWidget {
	const ClientCheckScreen({super.key});

	@override
	State<ClientCheckScreen> createState() => _ClientCheckScreenState();
}

class _ClientCheckScreenState extends State<ClientCheckScreen> {
	final _phoneController = TextEditingController();
	final _phoneFocusNode = FocusNode();
	ClientCheckResult? _result;
	String? _errorText;

	@override
	void initState() {
		super.initState();
		ClientCheckFlowService.instance.addListener(_onCheckFlowRequested);
		WidgetsBinding.instance.addPostFrameCallback((_) {
			_processPendingCheck();
		});
	}

	@override
	void dispose() {
		ClientCheckFlowService.instance.removeListener(_onCheckFlowRequested);
		_phoneController.dispose();
		_phoneFocusNode.dispose();
		super.dispose();
	}

	void _onCheckFlowRequested() {
		_processPendingCheck();
	}

	void _processPendingCheck() {
		final pendingPhone = ClientCheckFlowService.instance.consumePendingPhone();
		if (pendingPhone == null) {
			return;
		}

		final digits = extractPhoneDigits(pendingPhone);
		if (digits.length == 10) {
			_phoneController.text = formatPhoneInput(digits);
		} else {
			_phoneController.text = pendingPhone;
		}

		_runCheck();
	}

	void _clearPhoneInput() {
		_phoneController.clear();
	}

	void _runCheck() async {
		_phoneFocusNode.unfocus();

		final phoneText = _phoneController.text;

		if (!isPhoneComplete(phoneText)) {
			setState(() {
				_result = null;
				_errorText = 'Введите полный номер телефона';
			});
			return;
		}

		setState(() {
			_errorText = null;
		});

		final lookupResult = await ClientProfileService.lookupByPhone(phoneText);
		if (!mounted) {
			return;
		}

		if (lookupResult == null) {
			setState(() {
				_result = null;
				_errorText = 'Клиент не найден в базе сообщества';
			});
			_clearPhoneInput();
			return;
		}

		ClientProfileService.cacheProfile(
			extractPhoneDigits(phoneText),
			lookupResult.profile,
		);

		setState(() {
			_result = lookupResult;
			_errorText = null;
		});
		_clearPhoneInput();
	}

	void _openHowItWorks() {
		Navigator.of(context).pushNamed(HowItWorksScreen.routeName);
	}

	Future<void> _bookClient() async {
		final result = _result;
		if (result == null) {
			return;
		}

		final booked = await showBookClientDialog(
			context: context,
			checkResult: result,
		);

		if (!mounted || !booked) {
			return;
		}

		setState(() {
			_result = null;
			_errorText = null;
		});

		MainShellNavigation.instance.goToHome();

		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!mounted) {
				return;
			}

			AppSnackBar.show(
				context,
				'Клиент записан',
				type: AppSnackBarType.success,
			);
		});
	}

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: SingleChildScrollView(
				keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
				padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						const Center(
							child: Column(
								children: [
									AppLogo(size: 48),
									SizedBox(height: 10),
									BrandTitle(fontSize: 20),
								],
							),
						),
						const SizedBox(height: 28),
						const Text(
							'Проверка клиента',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 24,
								fontWeight: FontWeight.w700,
							),
						),
						const SizedBox(height: 8),
						const Text(
							'Узнайте надёжность клиента по номеру телефона',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textMuted,
								fontSize: 14,
								height: 1.4,
							),
						),
						const SizedBox(height: 24),
						ClientPhoneSearchBar(
							controller: _phoneController,
							focusNode: _phoneFocusNode,
							onSearch: _runCheck,
						),
						if (_errorText != null) ...[
							const SizedBox(height: 8),
							Text(
								_errorText!,
								textAlign: TextAlign.center,
								style: const TextStyle(
									color: AppColors.error,
									fontSize: 13,
								),
							),
						],
						const SizedBox(height: 12),
						Center(
							child: TextButton(
								onPressed: _openHowItWorks,
								child: const Text(
									'Как это работает?',
									style: TextStyle(
										color: AppColors.primary,
										fontSize: 14,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
						if (_result != null) ...[
							const SizedBox(height: 20),
							ClientCheckResultPanel(result: _result!),
							const SizedBox(height: 16),
							FilledButton.icon(
								onPressed: _bookClient,
								icon: const Icon(Icons.event_available_outlined),
								label: const Text('Записать клиента'),
							),
						],
					],
				),
			),
		);
	}
}
