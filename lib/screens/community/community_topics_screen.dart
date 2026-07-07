import 'package:flutter/material.dart';

import '../../services/community_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/community_topic_card.dart';
import 'community_chat_screen.dart';
import 'create_community_topic_screen.dart';

class CommunityTopicsScreen extends StatefulWidget {
	const CommunityTopicsScreen({super.key});

	@override
	State<CommunityTopicsScreen> createState() => _CommunityTopicsScreenState();
}

class _CommunityTopicsScreenState extends State<CommunityTopicsScreen> {
	final _searchController = TextEditingController();
	final _communityService = CommunityService.instance;
	var _searchQuery = '';

	@override
	void initState() {
		super.initState();
		_communityService.addListener(_onCommunityChanged);
		_searchController.addListener(_onSearchChanged);
	}

	@override
	void dispose() {
		_communityService.removeListener(_onCommunityChanged);
		_searchController.removeListener(_onSearchChanged);
		_searchController.dispose();
		super.dispose();
	}

	void _onCommunityChanged() {
		setState(() {});
	}

	void _onSearchChanged() {
		setState(() => _searchQuery = _searchController.text);
	}

	void _openCreateTopic() {
		Navigator.of(context).pushNamed(CreateCommunityTopicScreen.routeName);
	}

	void _openTopic(String topicId) {
		Navigator.of(context).pushNamed(
			CommunityChatScreen.routeName,
			arguments: topicId,
		);
	}

	@override
	Widget build(BuildContext context) {
		final referenceNow = DateTime.now();
		final topics = _communityService.topicsFor(_searchQuery);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					const _CommunityHeader(),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
						child: TextField(
							controller: _searchController,
							style: const TextStyle(color: AppColors.textPrimary),
							decoration: InputDecoration(
								hintText: 'Поиск по темам',
								hintStyle: const TextStyle(color: AppColors.textMuted),
								prefixIcon: const Icon(
									Icons.search_rounded,
									color: AppColors.textMuted,
								),
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
								isDense: true,
								contentPadding: const EdgeInsets.symmetric(
									horizontal: 12,
									vertical: 12,
								),
							),
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
						child: _CommunityPromoBanner(onCreateTopic: _openCreateTopic),
					),
					Expanded(
						child: topics.isEmpty
							? const _EmptyTopicsState()
							: ListView.separated(
								padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
								itemCount: topics.length,
								separatorBuilder: (context, index) =>
									const SizedBox(height: 10),
								itemBuilder: (context, index) {
									final topic = topics[index];

									return CommunityTopicCard(
										topic: topic,
										referenceNow: referenceNow,
										onOpen: () => _openTopic(topic.id),
									);
								},
							),
					),
				],
			),
		);
	}
}

class _CommunityHeader extends StatelessWidget {
	const _CommunityHeader();

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
			child: Row(
				children: [
					const SizedBox(width: 48),
					const Expanded(
						child: Text(
							'Сообщество',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 18,
								fontWeight: FontWeight.w600,
							),
						),
					),
					IconButton(
						onPressed: () {
							Navigator.of(context).pushNamed(
								CreateCommunityTopicScreen.routeName,
							);
						},
						icon: const Icon(
							Icons.add_circle_outline_rounded,
							color: AppColors.primary,
						),
					),
				],
			),
		);
	}
}

class _CommunityPromoBanner extends StatelessWidget {
	const _CommunityPromoBanner({required this.onCreateTopic});

	final VoidCallback onCreateTopic;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				gradient: LinearGradient(
					colors: [
						AppColors.primary.withValues(alpha: 0.9),
						AppColors.primary.withValues(alpha: 0.65),
					],
				),
				borderRadius: BorderRadius.circular(16),
			),
			child: Row(
				children: [
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Задайте вопрос мастерам',
									style: TextStyle(
										color: AppColors.textPrimary,
										fontSize: 18,
										fontWeight: FontWeight.w700,
									),
								),
								const SizedBox(height: 4),
								Text(
									'Создайте тему и обсудите её с участниками сообщества',
									style: TextStyle(
										color: AppColors.textPrimary.withValues(alpha: 0.85),
										fontSize: 13,
										height: 1.35,
									),
								),
							],
						),
					),
					const SizedBox(width: 12),
					FilledButton(
						onPressed: onCreateTopic,
						style: FilledButton.styleFrom(
							backgroundColor: AppColors.textPrimary,
							foregroundColor: AppColors.primary,
							minimumSize: const Size(0, 40),
							padding: const EdgeInsets.symmetric(horizontal: 16),
							textStyle: const TextStyle(
								fontSize: 14,
								fontWeight: FontWeight.w600,
							),
						),
						child: const Text('Создать'),
					),
				],
			),
		);
	}
}

class _EmptyTopicsState extends StatelessWidget {
	const _EmptyTopicsState();

	@override
	Widget build(BuildContext context) {
		return const Center(
			child: Padding(
				padding: EdgeInsets.symmetric(horizontal: 32),
				child: Text(
					'Темы не найдены. Попробуйте другой запрос или создайте новую.',
					textAlign: TextAlign.center,
					style: TextStyle(
						color: AppColors.textMuted,
						fontSize: 15,
						height: 1.4,
					),
				),
			),
		);
	}
}
