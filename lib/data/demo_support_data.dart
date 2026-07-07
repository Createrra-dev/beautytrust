import '../models/community_message.dart';
import '../models/support_ticket.dart';

class DemoSupportData {
	DemoSupportData._();

	static const currentUserName = 'Анна';
	static const supportAgentName = 'Техподдержка';

	static List<SupportTicket> tickets({DateTime? referenceNow}) {
		final now = referenceNow ?? DateTime.now();
		final today = DateTime(now.year, now.month, now.day);

		return [
			SupportTicket(
				id: 'support-1',
				title: 'Не обновляется рейтинг клиента',
				authorName: currentUserName,
				createdAt: today.subtract(const Duration(days: 1, hours: 3)),
				lastMessage: 'Проверьте, пожалуйста, обновление после смены номера.',
				lastMessageAt: today.subtract(const Duration(hours: 2)),
				status: SupportTicketStatus.inProgress,
			),
			SupportTicket(
				id: 'support-2',
				title: 'Вопрос по тарифу Мастер',
				authorName: currentUserName,
				createdAt: today.subtract(const Duration(days: 4)),
				lastMessage: 'Спасибо, всё понятно. Обращение закрыто.',
				lastMessageAt: today.subtract(const Duration(days: 3, hours: 5)),
				status: SupportTicketStatus.closed,
			),
		];
	}

	static Map<String, List<CommunityMessage>> messagesByTicket({
		DateTime? referenceNow,
	}) {
		final now = referenceNow ?? DateTime.now();
		final today = DateTime(now.year, now.month, now.day);

		return {
			'support-1': [
				CommunityMessage(
					id: 's1-m1',
					topicId: 'support-1',
					authorName: currentUserName,
					text:
						'После редактирования записи и смены телефона рейтинг клиента не обновился автоматически.',
					sentAt: today.subtract(const Duration(days: 1, hours: 3)),
					isMine: true,
				),
				CommunityMessage(
					id: 's1-m2',
					topicId: 'support-1',
					authorName: supportAgentName,
					text:
						'Здравствуйте! Мы получили обращение и уже проверяем сценарий обновления рейтинга.',
					sentAt: today.subtract(const Duration(days: 1, hours: 2, minutes: 40)),
					isMine: false,
				),
				CommunityMessage(
					id: 's1-m3',
					topicId: 'support-1',
					authorName: currentUserName,
					text: 'Проверьте, пожалуйста, обновление после смены номера.',
					sentAt: today.subtract(const Duration(hours: 2)),
					isMine: true,
				),
			],
			'support-2': [
				CommunityMessage(
					id: 's2-m1',
					topicId: 'support-2',
					authorName: currentUserName,
					text: 'Подскажите, входит ли проверка клиентов в тариф Мастер?',
					sentAt: today.subtract(const Duration(days: 4)),
					isMine: true,
				),
				CommunityMessage(
					id: 's2-m2',
					topicId: 'support-2',
					authorName: supportAgentName,
					text:
						'Да, в тарифе Мастер доступны все проверки клиентов без ограничений.',
					sentAt: today.subtract(const Duration(days: 3, hours: 6)),
					isMine: false,
				),
				CommunityMessage(
					id: 's2-m3',
					topicId: 'support-2',
					authorName: currentUserName,
					text: 'Спасибо, всё понятно. Обращение закрыто.',
					sentAt: today.subtract(const Duration(days: 3, hours: 5)),
					isMine: true,
				),
			],
		};
	}
}
