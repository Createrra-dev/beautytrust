import '../models/community_message.dart';
import '../models/community_topic.dart';

class DemoCommunityData {
	DemoCommunityData._();

	static const currentUserName = 'Анна';

	static List<CommunityTopic> topics({DateTime? referenceNow}) {
		final now = referenceNow ?? DateTime.now();
		final today = DateTime(now.year, now.month, now.day);

		return [
			CommunityTopic(
				id: 'topic-1',
				title: 'Как брать предоплату с новых клиентов?',
				authorName: 'Мария',
				createdAt: today.subtract(const Duration(days: 2)),
				participantCount: 24,
				lastMessage: 'Я прошу 30% при первой записи — работает отлично',
				lastMessageAt: today.add(const Duration(hours: 11, minutes: 36)),
				participantInitials: ['М', 'О', 'Е', 'А'],
				unreadCount: 2,
				isPinned: true,
				emoji: '💳',
			),
			CommunityTopic(
				id: 'topic-2',
				title: 'Клиент отменил в день записи',
				authorName: 'Ольга',
				createdAt: today.subtract(const Duration(days: 1)),
				participantCount: 18,
				lastMessage: 'Добавила правило отмены за 24 часа в описании услуги',
				lastMessageAt: today.add(const Duration(hours: 10, minutes: 15)),
				participantInitials: ['О', 'И', 'Н'],
				unreadCount: 0,
				emoji: '📅',
			),
			CommunityTopic(
				id: 'topic-3',
				title: 'Отзывы после неявки',
				authorName: 'Екатерина',
				createdAt: today.subtract(const Duration(days: 3)),
				participantCount: 31,
				lastMessage: 'Важно фиксировать неявки в BeautyTrust сразу после записи',
				lastMessageAt: today.add(const Duration(hours: 9, minutes: 42)),
				participantInitials: ['Е', 'С', 'Д', 'К'],
				unreadCount: 5,
				emoji: '⭐',
			),
			CommunityTopic(
				id: 'topic-4',
				title: 'Работа с токсичными клиентами',
				authorName: 'Светлана',
				createdAt: today.subtract(const Duration(days: 5)),
				participantCount: 42,
				lastMessage: 'Проверяйте номер до записи — сэкономите нервы',
				lastMessageAt: today.subtract(const Duration(hours: 2)),
				participantInitials: ['С', 'А', 'В', 'Л'],
				unreadCount: 0,
				emoji: '🛡️',
			),
		];
	}

	static Map<String, List<CommunityMessage>> messagesByTopic({
		DateTime? referenceNow,
	}) {
		final now = referenceNow ?? DateTime.now();
		final today = DateTime(now.year, now.month, now.day);

		return {
			'topic-1': [
				CommunityMessage(
					id: 'm-1-1',
					topicId: 'topic-1',
					authorName: 'Мария',
					text:
						'Девочки, как вы работаете с новыми клиентами без истории? '
						'Берёте предоплату или нет?',
					sentAt: today.add(const Duration(hours: 9, minutes: 10)),
				),
				CommunityMessage(
					id: 'm-1-2',
					topicId: 'topic-1',
					authorName: 'Ольга',
					text: 'Я всегда прошу 30% при первой записи. Если отказываются — это сигнал.',
					sentAt: today.add(const Duration(hours: 9, minutes: 45)),
				),
				CommunityMessage(
					id: 'm-1-3',
					topicId: 'topic-1',
					authorName: 'Екатерина',
					text: 'Согласна. Ещё проверяю номер в BeautyTrust до подтверждения.',
					sentAt: today.add(const Duration(hours: 10, minutes: 20)),
				),
				CommunityMessage(
					id: 'm-1-4',
					topicId: 'topic-1',
					authorName: 'Анна',
					text: 'Я прошу 30% при первой записи — работает отлично',
					sentAt: today.add(const Duration(hours: 11, minutes: 36)),
					isMine: true,
				),
			],
			'topic-2': [
				CommunityMessage(
					id: 'm-2-1',
					topicId: 'topic-2',
					authorName: 'Ольга',
					text: 'Сегодня клиентка отменила за 2 часа до визита. Как вы поступаете?',
					sentAt: today.add(const Duration(hours: 8, minutes: 30)),
				),
				CommunityMessage(
					id: 'm-2-2',
					topicId: 'topic-2',
					authorName: 'Ирина',
					text: 'У меня в правилах отмена не позднее чем за 24 часа.',
					sentAt: today.add(const Duration(hours: 9, minutes: 5)),
				),
				CommunityMessage(
					id: 'm-2-3',
					topicId: 'topic-2',
					authorName: 'Ольга',
					text: 'Добавила правило отмены за 24 часа в описании услуги',
					sentAt: today.add(const Duration(hours: 10, minutes: 15)),
				),
			],
			'topic-3': [
				CommunityMessage(
					id: 'm-3-1',
					topicId: 'topic-3',
					authorName: 'Екатерина',
					text: 'Стоит ли оставлять отзыв после неявки, если клиент не пришёл?',
					sentAt: today.subtract(const Duration(days: 1, hours: -14)),
				),
				CommunityMessage(
					id: 'm-3-2',
					topicId: 'topic-3',
					authorName: 'Дарья',
					text: 'Да, это помогает другим мастерам. Главное — без эмоций, по фактам.',
					sentAt: today.add(const Duration(hours: 8, minutes: 50)),
				),
				CommunityMessage(
					id: 'm-3-3',
					topicId: 'topic-3',
					authorName: 'Ксения',
					text: 'Важно фиксировать неявки в BeautyTrust сразу после записи',
					sentAt: today.add(const Duration(hours: 9, minutes: 42)),
				),
			],
			'topic-4': [
				CommunityMessage(
					id: 'm-4-1',
					topicId: 'topic-4',
					authorName: 'Светлана',
					text: 'Были случаи, когда клиентка писала грубости в личку после отказа. Как реагируете?',
					sentAt: today.subtract(const Duration(days: 1)),
				),
				CommunityMessage(
					id: 'm-4-2',
					topicId: 'topic-4',
					authorName: 'Алина',
					text: 'Блокирую и не трачу время на переписку. Репутация важнее.',
					sentAt: today.subtract(const Duration(hours: 5)),
				),
				CommunityMessage(
					id: 'm-4-3',
					topicId: 'topic-4',
					authorName: 'Виктория',
					text: 'Проверяйте номер до записи — сэкономите нервы',
					sentAt: today.subtract(const Duration(hours: 2)),
				),
			],
		};
	}
}
