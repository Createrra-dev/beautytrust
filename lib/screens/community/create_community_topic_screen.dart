import 'package:flutter/material.dart';

import '../../services/community_service.dart';
import '../../theme/app_theme.dart';

class CreateCommunityTopicScreen extends StatefulWidget {
	const CreateCommunityTopicScreen({super.key});

	static const routeName = '/community/create-topic';

	@override
	State<CreateCommunityTopicScreen> createState() =>
		_CreateCommunityTopicScreenState();
}

class _CreateCommunityTopicScreenState extends State<CreateCommunityTopicScreen> {
	final _titleController = TextEditingController();
	final _storyController = TextEditingController();
	final _communityService = CommunityService.instance;

	@override
	void dispose() {
		_titleController.dispose();
		_storyController.dispose();
		super.dispose();
	}

	bool get _canCreate {
		return _titleController.text.trim().isNotEmpty &&
			_storyController.text.trim().isNotEmpty;
	}

	void _createTopic() {
		if (!_canCreate) {
			return;
		}

		_communityService.createTopic(
			title: _titleController.text,
			story: _storyController.text,
		);

		Navigator.of(context).pop();
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
										'Новая тема',
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
										'Расскажите о вопросе или ситуации, которую хотите обсудить с мастерами',
										style: TextStyle(
											color: AppColors.textMuted,
											fontSize: 15,
											height: 1.4,
										),
									),
									const SizedBox(height: 20),
									_TextFieldBlock(
										label: 'Тема',
										controller: _titleController,
										hintText: 'Например: Как брать предоплату?',
										maxLines: 1,
										onChanged: (_) => setState(() {}),
									),
									const SizedBox(height: 16),
									_TextFieldBlock(
										label: 'Ваш вопрос или история',
										controller: _storyController,
										hintText:
											'Опишите ситуацию — другие мастера смогут ответить и поделиться опытом',
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
							onPressed: _canCreate ? _createTopic : null,
							child: const Text('Опубликовать тему'),
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
