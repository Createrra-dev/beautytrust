import 'package:flutter/material.dart';

import '../../services/support_service.dart';
import '../../theme/app_theme.dart';
import 'support_chat_screen.dart';

class CreateSupportTicketScreen extends StatefulWidget {
	const CreateSupportTicketScreen({super.key});

	static const routeName = '/support/create-ticket';

	@override
	State<CreateSupportTicketScreen> createState() =>
		_CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
	final _titleController = TextEditingController();
	final _descriptionController = TextEditingController();
	final _supportService = SupportService.instance;

	@override
	void dispose() {
		_titleController.dispose();
		_descriptionController.dispose();
		super.dispose();
	}

	bool get _canCreate {
		return _titleController.text.trim().isNotEmpty &&
			_descriptionController.text.trim().isNotEmpty;
	}

	void _createTicket() async {
		if (!_canCreate) {
			return;
		}

		final ticket = await _supportService.createTicket(
			title: _titleController.text,
			description: _descriptionController.text,
		);

		if (!mounted) {
			return;
		}

		Navigator.of(context)
			..pop()
			..pushNamed(
				SupportChatScreen.routeName,
				arguments: ticket.id,
			);
	}

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
						child: Row(
							children: [
								IconButton(
									onPressed: () => Navigator.of(context).pop(),
									icon: const Icon(
										Icons.arrow_back_ios_new_rounded,
										color: AppColors.textPrimary,
										size: 20,
									),
								),
								const Expanded(
									child: Text(
										'Новое обращение',
										textAlign: TextAlign.center,
										style: TextStyle(
											color: AppColors.textPrimary,
											fontSize: 18,
											fontWeight: FontWeight.w600,
										),
									),
								),
								const SizedBox(width: 48),
							],
						),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									const Text(
										'Опишите проблему — специалист техподдержки ответит в этом диалоге',
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 15,
											height: 1.4,
										),
									),
									const SizedBox(height: 20),
									_TextFieldBlock(
										label: 'Тема обращения',
										controller: _titleController,
										hintText: 'Например: Не обновляется рейтинг клиента',
										maxLines: 1,
										onChanged: (_) => setState(() {}),
									),
									const SizedBox(height: 16),
									_TextFieldBlock(
										label: 'Описание проблемы',
										controller: _descriptionController,
										hintText:
											'Расскажите, что произошло и какие шаги уже пробовали',
										maxLines: 6,
										onChanged: (_) => setState(() {}),
									),
								],
							),
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
						child: FilledButton(
							onPressed: _canCreate ? _createTicket : null,
							child: const Text('Отправить обращение'),
						),
					),
				],
			),
		);
	}
}

class _TextFieldBlock extends StatelessWidget {
	const _TextFieldBlock({
		required this.label,
		required this.controller,
		required this.hintText,
		required this.maxLines,
		required this.onChanged,
	});

	final String label;
	final TextEditingController controller;
	final String hintText;
	final int maxLines;
	final ValueChanged<String> onChanged;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					label,
					style: const TextStyle(
						color: AppColors.textPrimary,
						fontSize: 14,
						fontWeight: FontWeight.w600,
					),
				),
				const SizedBox(height: 8),
				TextField(
					controller: controller,
					onChanged: onChanged,
					maxLines: maxLines,
					style: const TextStyle(color: AppColors.textPrimary),
					decoration: InputDecoration(
						hintText: hintText,
						hintStyle: const TextStyle(color: AppColors.textMuted),
						filled: true,
						fillColor: AppColors.surface,
						border: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: const BorderSide(color: AppColors.border),
						),
						enabledBorder: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: const BorderSide(color: AppColors.border),
						),
						focusedBorder: OutlineInputBorder(
							borderRadius: BorderRadius.circular(12),
							borderSide: const BorderSide(color: AppColors.primary),
						),
					),
				),
			],
		);
	}
}
