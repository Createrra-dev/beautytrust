import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HowItWorksScreen extends StatelessWidget {
	const HowItWorksScreen({super.key});

	static const routeName = '/how-it-works';

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
										'Как это работает',
										style: TextStyle(
											color: AppColors.textPrimary,
											fontSize: 18,
											fontWeight: FontWeight.w600,
										),
									),
								),
							],
						),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									_buildSection(
										title: 'Что делает проверка',
										text:
											'Beauty Trust ищет номер телефона в базе сообщества мастеров '
											'и собирает доступные сигналы: отзывы коллег, неявки, '
											'переносы и конфликтные ситуации за последние месяцы.',
									),
									const SizedBox(height: 20),
									_buildSection(
										title: 'Как формируется оценка',
										text:
											'Алгоритм агрегирует оценки мастеров и поведенческие метрики '
											'в единый рейтинг надёжности. Чем больше подтверждённых '
											'отзывов в сообществе, тем точнее картина по клиенту.',
									),
									const SizedBox(height: 20),
									_buildSection(
										title: 'Это рекомендация, не приговор',
										text:
											'Результат проверки — рекомендательная подсказка, а не '
											'юридическое решение. Окончательный выбор всегда остаётся '
											'за мастером: записать клиента, запросить предоплату '
											'или отказать в записи.',
									),
									const SizedBox(height: 20),
									Container(
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(
											color: AppColors.surface,
											borderRadius: BorderRadius.circular(14),
											border: Border.all(color: AppColors.border),
										),
										child: const Text(
											'Данные обезличены и используются только внутри '
											'закрытого сообщества Beauty Trust для защиты мастеров.',
											style: TextStyle(
												color: AppColors.textMuted,
												fontSize: 14,
												height: 1.45,
											),
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}

	Widget _buildSection({
		required String title,
		required String text,
	}) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					title,
					style: const TextStyle(
						color: AppColors.textPrimary,
						fontSize: 16,
						fontWeight: FontWeight.w600,
					),
				),
				const SizedBox(height: 8),
				Text(
					text,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 14,
						height: 1.45,
					),
				),
			],
		);
	}
}
