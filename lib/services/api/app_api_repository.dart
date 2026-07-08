import '../../models/appointment_record.dart';
import '../../models/check_history_record.dart';
import '../../models/client_check_result.dart';
import '../../models/client_profile.dart';
import '../../models/community_message.dart';
import '../../models/community_topic.dart';
import '../../models/dashboard_period.dart';
import '../../models/dashboard_stats.dart';
import '../../models/master_profile.dart';
import '../../models/master_service.dart';
import '../../models/support_ticket.dart';
import '../../models/visit_result.dart';
import '../../utils/phone_formatter.dart';
import 'beauty_trust_api.dart';

class AppApiRepository {
	AppApiRepository({BeautyTrustApi? api}) : _api = api ?? BeautyTrustApi();

	final BeautyTrustApi _api;

	Future<List<AppointmentRecord>> fetchAppointments({
		DateTime? from,
		DateTime? to,
		int limit = 100,
		int offset = 0,
	}) async {
		final query = <String, String>{
			'limit': '$limit',
			'offset': '$offset',
		};
		if (from != null) {
			query['from'] = from.toUtc().toIso8601String();
		}
		if (to != null) {
			query['to'] = to.toUtc().toIso8601String();
		}

		final items = await _api.getJsonList('/api/appointments', query: query);
		return items.map((item) => _appointmentFromJson(item as Map<String, dynamic>)).toList();
	}

	Future<AppointmentRecord> fetchAppointment(String appointmentId) async {
		final json = await _api.getJson('/api/appointments/$appointmentId');
		return _appointmentFromJson(json);
	}

	Future<AppointmentRecord> createAppointment(AppointmentRecord appointment) async {
		final json = await _api.postJson('/api/appointments', body: _appointmentToJson(appointment));
		return _appointmentFromJson(json);
	}

	Future<AppointmentRecord> updateAppointment(AppointmentRecord appointment) async {
		final json = await _api.patchJson(
			'/api/appointments/${appointment.id}',
			body: {
				'client_name': appointment.clientName,
				'client_phone_digits': appointment.clientPhoneDigits,
				'service_name': appointment.serviceName,
				'service_duration_label': appointment.serviceDurationLabel,
				'scheduled_at': appointment.scheduledAt.toUtc().toIso8601String(),
				'service_price': appointment.servicePrice,
				'client_rating': appointment.clientRating,
				'risk_level': _riskLevelName(appointment.riskLevel),
				'days_since_verified': appointment.daysSinceVerified,
			},
		);
		return _appointmentFromJson(json);
	}

	Future<void> deleteAppointment(String appointmentId) async {
		await _api.deleteJson('/api/appointments/$appointmentId');
	}

	Future<AppointmentRecord> saveVisitResult(
		String appointmentId,
		VisitResult visitResult,
	) async {
		final json = await _api.postJson(
			'/api/appointments/$appointmentId/visit-result',
			body: {
				'punctuality': visitResult.punctuality.name == 'onTime'
					? 'onTime'
					: visitResult.punctuality.name == 'late'
						? 'late'
						: 'noShow',
				'paid_in_full': visitResult.paidInFull,
				'had_scandal': visitResult.hadScandal,
				'left_tips': visitResult.leftTips,
				'comment': visitResult.comment,
			},
		);
		return _appointmentFromJson(json);
	}

	Future<ClientCheckResult?> checkClient(String phone) async {
		try {
			final json = await _api.postJson('/api/clients/check', body: {'phone': phone});
			return _clientCheckFromJson(json);
		} on ApiException catch (error) {
			if (error.statusCode == 404) {
				return null;
			}
			rethrow;
		}
	}

	Future<List<CheckHistoryRecord>> fetchCheckHistory({
		CheckHistoryFilter filter = CheckHistoryFilter.all,
	}) async {
		final filterValue = switch (filter) {
			CheckHistoryFilter.all => 'all',
			CheckHistoryFilter.reliable => 'reliable',
			CheckHistoryFilter.risky => 'risky',
		};
		final items = await _api.getJsonList(
			'/api/checks/history',
			query: {'filter': filterValue},
		);
		return items
			.map((item) => _checkHistoryFromJson(item as Map<String, dynamic>))
			.toList();
	}

	Future<DashboardStats> fetchDashboardStats({
		required int year,
		required int month,
	}) async {
		final json = await _api.getJson(
			'/api/dashboard/stats',
			query: {
				'year': '$year',
				'month': '$month',
			},
		);
		return DashboardStats(
			periodLabel: json['period_label'] as String,
			protectedIncome: json['protected_income'] as int,
			incomeTrendLabel: json['income_trend_label'] as String,
			incomeTrendPositive: json['income_trend_positive'] as bool,
			sparklineValues: (json['sparkline_values'] as List<dynamic>)
				.map((item) => (item as num).toDouble())
				.toList(),
			preventedNoShows: json['prevented_no_shows'] as int,
			noShowsTrendLabel: json['no_shows_trend_label'] as String,
			completedChecks: json['completed_checks'] as int,
			checksTrendLabel: json['checks_trend_label'] as String,
		);
	}

	Future<List<DashboardPeriod>> fetchDashboardPeriods() async {
		final items = await _api.getJsonList('/api/dashboard/periods');
		return items.map((item) {
			final json = item as Map<String, dynamic>;
			return DashboardPeriod(
				year: json['year'] as int,
				month: json['month'] as int,
			);
		}).toList();
	}

	Future<List<MasterService>> fetchMasterServices() async {
		final items = await _api.getJsonList('/api/master/services');
		return items.map((item) {
			final json = item as Map<String, dynamic>;
			return MasterService(
				id: json['id'] as int?,
				name: json['name'] as String,
				durationLabel: json['duration_label'] as String,
				price: json['price'] as int,
			);
		}).toList();
	}

	Future<List<CommunityTopic>> fetchCommunityTopics({String query = ''}) async {
		final items = await _api.getJsonList('/api/community/topics', query: {'q': query});
		return items.map((item) => _communityTopicFromJson(item as Map<String, dynamic>)).toList();
	}

	Future<CommunityTopic> createCommunityTopic({
		required String title,
		required String story,
	}) async {
		final json = await _api.postJson('/api/community/topics', body: {
			'title': title,
			'story': story,
		});
		return _communityTopicFromJson(json);
	}

	Future<List<CommunityMessage>> fetchCommunityMessages(String topicId) async {
		final items = await _api.getJsonList('/api/community/topics/$topicId/messages');
		return items.map((item) => _communityMessageFromJson(item as Map<String, dynamic>)).toList();
	}

	Future<CommunityMessage> sendCommunityMessage({
		required String topicId,
		required String text,
	}) async {
		final json = await _api.postJson(
			'/api/community/topics/$topicId/messages',
			body: {'text': text},
		);
		return _communityMessageFromJson(json);
	}

	Future<List<SupportTicket>> fetchSupportTickets({String query = ''}) async {
		final items = await _api.getJsonList('/api/support/tickets', query: {'q': query});
		return items.map((item) => _supportTicketFromJson(item as Map<String, dynamic>)).toList();
	}

	Future<SupportTicket> createSupportTicket({
		required String title,
		required String description,
	}) async {
		final json = await _api.postJson('/api/support/tickets', body: {
			'title': title,
			'description': description,
		});
		return _supportTicketFromJson(json);
	}

	Future<List<CommunityMessage>> fetchSupportMessages(String ticketId) async {
		final items = await _api.getJsonList('/api/support/tickets/$ticketId/messages');
		return items.map((item) => _communityMessageFromJson(item as Map<String, dynamic>)).toList();
	}

	Future<CommunityMessage> sendSupportMessage({
		required String ticketId,
		required String text,
	}) async {
		final json = await _api.postJson(
			'/api/support/tickets/$ticketId/messages',
			body: {'text': text},
		);
		return _communityMessageFromJson(json);
	}

	Future<void> cancelSupportTicket(String ticketId) async {
		await _api.postJson('/api/support/tickets/$ticketId/cancel');
	}

	Future<MasterProfile> fetchProfile() async {
		final json = await _api.getJson('/api/profile');
		return _masterProfileFromJson(json);
	}

	Future<MasterProfile> updateProfile({
		String? firstName,
		String? email,
		String? badgeLabel,
	}) async {
		final body = <String, dynamic>{};
		if (firstName != null) {
			body['first_name'] = firstName;
		}
		if (email != null) {
			body['email'] = email;
		}
		if (badgeLabel != null) {
			body['badge_label'] = badgeLabel;
		}
		final json = await _api.patchJson('/api/profile', body: body);
		return _masterProfileFromJson(json);
	}

	Future<MasterProfile> uploadAvatar(String filePath) async {
		final json = await _api.multipartPost(
			'/api/profile/avatar',
			fieldName: 'file',
			filePath: filePath,
			filename: 'avatar.jpg',
		);
		return _masterProfileFromJson(json);
	}

	Future<MasterProfile> deleteAvatar() async {
		final json = await _api.deleteJson('/api/profile/avatar');
		return _masterProfileFromJson(json);
	}

	MasterProfile _masterProfileFromJson(Map<String, dynamic> json) {
		return MasterProfile(
			firstName: json['first_name'] as String,
			badgeLabel: json['badge_label'] as String,
			rating: (json['rating'] as num).toDouble(),
			reviewsCount: json['reviews_count'] as int,
			clientsCount: json['clients_count'] as int,
			preventedNoShows: json['prevented_no_shows'] as int,
			protectedIncome: json['protected_income'] as int,
			tariffLabel: json['tariff_label'] as String,
			email: json['email'] as String?,
			phoneDigits: json['phone_digits'] as String?,
			avatarUrl: json['avatar_url'] as String?,
			yearsExperience: json['years_experience'] as int? ?? 0,
		);
	}

	AppointmentRecord _appointmentFromJson(Map<String, dynamic> json) {
		VisitResult? visitResult;
		final visitJson = json['visit_result'] as Map<String, dynamic>?;
		if (visitJson != null) {
			visitResult = VisitResult(
				punctuality: _punctualityFromApi(visitJson['punctuality'] as String),
				paidInFull: visitJson['paid_in_full'] as bool,
				hadScandal: visitJson['had_scandal'] as bool,
				leftTips: visitJson['left_tips'] as bool,
				comment: visitJson['comment'] as String?,
			);
		}

		return AppointmentRecord(
			id: json['id'] as String,
			clientName: json['client_name'] as String,
			clientPhoneDigits: json['client_phone_digits'] as String,
			serviceName: json['service_name'] as String,
			serviceDurationLabel: json['service_duration_label'] as String,
			scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
			servicePrice: json['service_price'] as int,
			clientRating: (json['client_rating'] as num).toDouble(),
			riskLevel: _riskLevelFromApi(json['risk_level'] as String),
			daysSinceVerified: json['days_since_verified'] as int,
			visitResult: visitResult,
		);
	}

	Map<String, dynamic> _appointmentToJson(AppointmentRecord appointment) {
		return {
			'client_name': appointment.clientName,
			'client_phone_digits': appointment.clientPhoneDigits,
			'service_name': appointment.serviceName,
			'service_duration_label': appointment.serviceDurationLabel,
			'scheduled_at': appointment.scheduledAt.toUtc().toIso8601String(),
			'service_price': appointment.servicePrice,
			'client_rating': appointment.clientRating,
			'risk_level': _riskLevelName(appointment.riskLevel),
			'days_since_verified': appointment.daysSinceVerified,
		};
	}

	CheckHistoryRecord _checkHistoryFromJson(Map<String, dynamic> json) {
		final phoneDigits = json['phone_digits'] as String? ?? '';
		return CheckHistoryRecord(
			id: json['id'] as String,
			phone: phoneDigits.length == 10
				? formatPhoneDisplay(phoneDigits)
				: phoneDigits,
			rating: (json['rating'] as num).toDouble(),
			checkedAt: DateTime.parse(json['checked_at'] as String).toLocal(),
			clientName: json['client_name'] as String?,
			riskLevel: json['risk_level'] is String
				? _riskLevelFromApi(json['risk_level'] as String)
				: null,
		);
	}

	ClientCheckResult _clientCheckFromJson(Map<String, dynamic> json) {
		final profileJson = json['profile'] as Map<String, dynamic>;
		final reviews = (profileJson['reviews'] as List<dynamic>).map((item) {
			final review = item as Map<String, dynamic>;
			return MasterReview(
				masterName: review['author_name'] as String,
				rating: (review['rating'] as num).toDouble(),
				text: review['text'] as String,
				tag: 'отзыв',
				ratedAt: DateTime(review['review_year'] as int, review['review_month'] as int),
			);
		}).toList();

		return ClientCheckResult(
			clientName: json['client_name'] as String,
			profile: ClientProfile(
				phone: profileJson['phone'] as String,
				ratingLabel: profileJson['rating_label'] as String,
				reviewsAverage: (profileJson['reviews_average'] as num).toDouble(),
				reviewsCount: profileJson['reviews_count'] as int,
				noShowsCount: profileJson['no_shows_count'] as int,
				scandalsCount: profileJson['scandals_count'] as int,
				reviews: reviews,
				reliabilityTitle: profileJson['reliability_title'] as String,
				reliabilitySubtitle: profileJson['reliability_subtitle'] as String,
			),
		);
	}

	CommunityTopic _communityTopicFromJson(Map<String, dynamic> json) {
		return CommunityTopic(
			id: json['id'] as String,
			title: json['title'] as String,
			authorName: json['author_name'] as String,
			createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
			participantCount: json['participant_count'] as int,
			lastMessage: json['last_message'] as String,
			lastMessageAt: DateTime.parse(json['last_message_at'] as String).toLocal(),
			participantInitials: (json['participant_initials'] as List<dynamic>).cast<String>(),
			unreadCount: json['unread_count'] as int? ?? 0,
			isPinned: json['is_pinned'] as bool? ?? false,
			emoji: json['emoji'] as String? ?? '💬',
		);
	}

	CommunityMessage _communityMessageFromJson(Map<String, dynamic> json) {
		return CommunityMessage(
			id: json['id'] as String,
			topicId: json['topic_id'] as String,
			authorName: json['author_name'] as String,
			text: json['text'] as String,
			sentAt: DateTime.parse(json['sent_at'] as String).toLocal(),
			isMine: json['is_mine'] as bool,
		);
	}

	SupportTicket _supportTicketFromJson(Map<String, dynamic> json) {
		return SupportTicket(
			id: json['id'] as String,
			title: json['title'] as String,
			authorName: json['author_name'] as String,
			createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
			lastMessage: json['last_message'] as String,
			lastMessageAt: DateTime.parse(json['last_message_at'] as String).toLocal(),
			status: _supportStatusFromApi(json['status'] as String),
			unreadCount: json['unread_count'] as int? ?? 0,
		);
	}

	VisitPunctuality _punctualityFromApi(String value) {
		return switch (value) {
			'onTime' => VisitPunctuality.onTime,
			'late' => VisitPunctuality.late,
			_ => VisitPunctuality.noShow,
		};
	}

	AppointmentRiskLevel _riskLevelFromApi(String value) {
		return switch (value) {
			'low' => AppointmentRiskLevel.low,
			'medium' => AppointmentRiskLevel.medium,
			_ => AppointmentRiskLevel.high,
		};
	}

	String _riskLevelName(AppointmentRiskLevel value) {
		return switch (value) {
			AppointmentRiskLevel.low => 'low',
			AppointmentRiskLevel.medium => 'medium',
			AppointmentRiskLevel.high => 'high',
		};
	}

	SupportTicketStatus _supportStatusFromApi(String value) {
		return switch (value) {
			'new' => SupportTicketStatus.newTicket,
			'in_progress' => SupportTicketStatus.inProgress,
			'waiting_for_response' => SupportTicketStatus.waitingForResponse,
			'closed' => SupportTicketStatus.closed,
			_ => SupportTicketStatus.cancelled,
		};
	}
}
