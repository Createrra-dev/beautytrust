import 'package:flutter/material.dart';

import '../../services/client_check_flow_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../app_snack_bar.dart';
import '../check/client_phone_search_bar.dart';

class HomeQuickPhoneCheck extends StatefulWidget {
	const HomeQuickPhoneCheck({super.key});

	@override
	State<HomeQuickPhoneCheck> createState() => _HomeQuickPhoneCheckState();
}

class _HomeQuickPhoneCheckState extends State<HomeQuickPhoneCheck> {
	final _phoneController = TextEditingController();
	final _phoneFocusNode = FocusNode();

	@override
	void dispose() {
		_phoneController.dispose();
		_phoneFocusNode.dispose();
		super.dispose();
	}

	void _runCheck() {
		_phoneFocusNode.unfocus();

		if (!isPhoneComplete(_phoneController.text)) {
			AppSnackBar.show(
				context,
				'Введите полный номер телефона',
				type: AppSnackBarType.error,
			);
			return;
		}

		ClientCheckFlowService.instance.checkPhoneFromHome(_phoneController.text);
		_phoneController.clear();
	}

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Text(
					'Проверить клиента',
					style: TextStyle(
						color: AppColors.textPrimary,
						fontSize: 14,
						fontWeight: FontWeight.w600,
					),
				),
				const SizedBox(height: 8),
				ClientPhoneSearchBar(
					controller: _phoneController,
					focusNode: _phoneFocusNode,
					onSearch: _runCheck,
				),
			],
		);
	}
}
