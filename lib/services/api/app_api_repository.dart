import '../../models/appointment_record.dart';
import '../../models/app_notification.dart';
import '../../models/check_history_record.dart';
import '../../models/client_check_result.dart';
import '../../models/client_profile.dart';
import '../../models/community_message.dart';
import '../../models/community_topic.dart';
import '../../models/dashboard_period.dart';
import '../../models/dashboard_stats.dart';
import '../../models/master_profile.dart';
import '../../models/master_service.dart';
import '../../models/master_settings.dart';
import '../../models/profile_stats.dart';
import '../../models/support_ticket.dart';
import '../../models/tariff_plan.dart';
import '../../models/visit_result.dart';
import '../../models/yclients_integration.dart';
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
				'had_behavior_issues': visitResult.hadBehaviorIssues,
				'was_unfriendly': visitResult.wasUnfriendly,
				'had_scandal': visitResult.hadScandal,
				'threatened_complaints': visitResult.threatenedComplaints,
				'demanded_discount': visitResult.demandedDiscount,
				'stole_from_salon': visitResult.stoleFromSalon,
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

	Future<ClientProfile> fetchClientProfile(String phoneDigits) async {
		final json = await _api.getJson('/api/clients/$phoneDigits');
		return _clientProfileFromJson(json);
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
			return _masterServiceFromJson(json);
		}).toList();
	}

	Future<MasterService> createMasterService({
		required String name,
		required String durationLabel,
		required int price,
	}) async {
		final json = await _api.postJson(
			'/api/master/services',
			body: {
				'name': name,
				'duration_label': durationLabel,
				'price': price,
			},
		);
		return _masterServiceFromJson(json);
	}

	Future<MasterService> updateMasterService({
		required int serviceId,
		required String name,
		required String durationLabel,
		required int price,
	}) async {
		final json = await _api.patchJson(
			'/api/master/services/$serviceId',
			body: {
				'name': name,
				'duration_label': durationLabel,
				'price': price,
			},
		);
		return _masterServiceFromJson(json);
	}

	Future<void> deleteMasterService(int serviceId) async {
		await _api.deleteJson('/api/master/services/$serviceId');
	}

	MasterService _masterServiceFromJson(Map<String, dynamic> json) {
		return MasterService(
			id: json['id'] as int?,
			name: json['name'] as String,
			durationLabel: json['duration_label'] as String,
			price: json['price'] as int,
			isOwned: json['is_owned'] as bool? ?? false,
		);
	}

	Future<List<CommunityTopic>> fetchCommunityTopics({
		String query = '',
		int limit = 50,
		int offset = 0,
	}) async {
		final items = await _api.getJsonList(
			'/api/community/topics',
			query: {
				'q': query,
				'limit': '$limit',
				'offset': '$offset',
			},
		);
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

	Future<CommunityTopic> markCommunityTopicRead(String topicId) async {
		final json = await _api.patchJson('/api/community/topics/$topicId/read');
		return _communityTopicFromJson(json);
	}

	Future<CommunityTopic> closeCommunityTopic(String topicId) async {
		final json = await _api.postJson('/api/community/topics/$topicId/close');
		return _communityTopicFromJson(json);
	}

	Future<List<CommunityMessage>> fetchCommunityMessages(
		String topicId, {
		int limit = 100,
		int offset = 0,
	}) async {
		final items = await _api.getJsonList(
			'/api/community/topics/$topicId/messages',
			query: {
				'limit': '$limit',
				'offset': '$offset',
			},
		);
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

	Future<List<SupportTicket>> fetchSupportTickets({
		String query = '',
		int limit = 50,
		int offset = 0,
	}) async {
		final items = await _api.getJsonList(
			'/api/support/tickets',
			query: {
				'q': query,
				'limit': '$limit',
				'offset': '$offset',
			},
		);
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

	Future<List<CommunityMessage>> fetchSupportMessages(
		String ticketId, {
		int limit = 100,
		int offset = 0,
	}) async {
		final items = await _api.getJsonList(
			'/api/support/tickets/$ticketId/messages',
			query: {
				'limit': '$limit',
				'offset': '$offset',
			},
		);
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

	Future<CommunityMessage> uploadSupportAttachment({
		required String ticketId,
		required String filePath,
		String? filename,
	}) async {
		final json = await _api.multipartPost(
			'/api/support/tickets/$ticketId/attachments',
			fieldName: 'file',
			filePath: filePath,
			filename: filename,
		);
		return _communityMessageFromJson(json);
	}

	Future<void> cancelSupportTicket(String ticketId) async {
		await _api.postJson('/api/support/tickets/$ticketId/cancel');
	}

	Future<void> registerDevice({
		required String token,
		String platform = 'ios',
	}) async {
		await _api.postJson(
			'/api/devices/register',
			body: {
				'token': token,
				'platform': platform,
			},
		);
	}

	Future<List<AppNotification>> fetchNotifications({
		int limit = 50,
		int offset = 0,
	}) async {
		final items = await _api.getJsonList(
			'/api/notifications',
			query: {
				'limit': '$limit',
				'offset': '$offset',
			},
		);
		return items
			.map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
			.toList();
	}

	Future<AppNotification> markNotificationRead(int notificationId) async {
		final json = await _api.patchJson('/api/notifications/$notificationId/read');
		return AppNotification.fromJson(json);
	}

	Future<List<TariffPlan>> fetchTariffs({String? audience}) async {
		final query = <String, String>{};
		if (audience != null) {
			query['audience'] = audience;
		}
		final items = await _api.getJsonList('/api/tariffs', query: query.isEmpty ? null : query);
		return items
			.map((item) => TariffPlan.fromJson(item as Map<String, dynamic>))
			.toList();
	}

	Future<MasterSubscription> fetchSubscription() async {
		final json = await _api.getJson('/api/profile/subscription');
		return MasterSubscription.fromJson(json);
	}

	Future<SubscribeResult> subscribeToPlan({
		required String planId,
		required int months,
		String? returnBaseUrl,
	}) async {
		final body = <String, dynamic>{'months': months};
		if (returnBaseUrl != null) {
			body['return_base_url'] = returnBaseUrl;
		}
		final json = await _api.postJson('/api/tariffs/$planId/subscribe', body: body);
		return SubscribeResult.fromJson(json);
	}

	Future<MasterProfile> fetchProfile() async {
		final json = await _api.getJson('/api/profile');
		return _masterProfileFromJson(json);
	}

	Future<void> completeOnboarding() async {
		await _api.postJson('/api/profile/onboarding/complete', body: {});
	}

	Future<ProfileStats> fetchProfileStats() async {
		final json = await _api.getJson('/api/profile/stats');
		return ProfileStats(
			appointmentsTotal: json['appointments_total'] as int,
			appointmentsScheduled: json['appointments_scheduled'] as int,
			appointmentsCompleted: json['appointments_completed'] as int,
			appointmentsNoShow: json['appointments_no_show'] as int,
			appointmentsCancelled: json['appointments_cancelled'] as int,
			completionRate: (json['completion_rate'] as num).toDouble(),
			avgClientRating: (json['avg_client_rating'] as num).toDouble(),
			checksTotal: json['checks_total'] as int,
			reviewsGiven: json['reviews_given'] as int,
		);
	}

	Future<List<MasterReview>> fetchProfileReviews() async {
		final items = await _api.getJsonList('/api/profile/reviews');
		return items.map((item) {
			final json = item as Map<String, dynamic>;
			final rating = (json['rating'] as num).toDouble();
			return MasterReview(
				masterName: json['author_name'] as String,
				rating: rating,
				text: json['text'] as String,
				tag: appointmentRatingLabel(rating),
				ratedAt: DateTime(
					json['review_year'] as int,
					json['review_month'] as int,
				),
			);
		}).toList();
	}

	Future<MasterSettings> fetchProfileSettings() async {
		final json = await _api.getJson('/api/profile/settings');
		return _masterSettingsFromJson(json);
	}

	Future<MasterSettings> updateProfileSettings(MasterSettings settings) async {
		final json = await _api.patchJson(
			'/api/profile/settings',
			body: {
				'push_notifications_enabled': settings.pushNotificationsEnabled,
				'email_notifications_enabled': settings.emailNotificationsEnabled,
				'marketing_notifications_enabled': settings.marketingNotificationsEnabled,
				'visit_result_defaults_enabled': settings.visitResultDefaultsEnabled,
			},
		);
		return _masterSettingsFromJson(json);
	}

	Future<YClientsIntegration> fetchYClientsIntegration() async {
		final json = await _api.getJson('/api/profile/yclients');
		return _yClientsIntegrationFromJson(json);
	}

	Future<YClientsIntegration> updateYClientsIntegration({
		bool? enabled,
		String? partnerToken,
		String? companyId,
		String? login,
		String? password,
		String? authCode,
		int? syncIntervalMinutes,
	}) async {
		final body = <String, dynamic>{};
		if (enabled != null) {
			body['enabled'] = enabled;
		}
		if (partnerToken != null) {
			body['partner_token'] = partnerToken;
		}
		if (companyId != null) {
			body['company_id'] = companyId;
		}
		if (login != null) {
			body['login'] = login;
		}
		if (password != null) {
			body['password'] = password;
		}
		if (authCode != null) {
			body['auth_code'] = authCode;
		}
		if (syncIntervalMinutes != null) {
			body['sync_interval_minutes'] = syncIntervalMinutes;
		}

		final json = await _api.patchJson('/api/profile/yclients', body: body);
		return _yClientsIntegrationFromJson(json);
	}

	Future<YClientsSyncResult> syncYClientsIntegration() async {
		final json = await _api.postJson('/api/profile/yclients/sync', body: {});
		return YClientsSyncResult(
			imported: json['imported'] as int? ?? 0,
			updated: json['updated'] as int? ?? 0,
			skipped: json['skipped'] as int? ?? 0,
		);
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
			final hadScandal = visitJson['had_scandal'] as bool? ?? false;
			visitResult = VisitResult(
				punctuality: _punctualityFromApi(visitJson['punctuality'] as String),
				paidInFull: visitJson['paid_in_full'] as bool,
				hadBehaviorIssues:
					visitJson['had_behavior_issues'] as bool? ?? hadScandal,
				wasUnfriendly: visitJson['was_unfriendly'] as bool? ?? false,
				hadScandal: hadScandal,
				threatenedComplaints: visitJson['threatened_complaints'] as bool? ?? false,
				demandedDiscount: visitJson['demanded_discount'] as bool? ?? false,
				stoleFromSalon: visitJson['stole_from_salon'] as bool? ?? false,
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
			status: _statusFromApi(json['status'] as String? ?? 'scheduled'),
			visitResult: visitResult,
			source: json['source'] as String? ?? 'manual',
			yclientsStaffName: json['yclients_staff_name'] as String?,
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
		return ClientCheckResult(
			clientName: json['client_name'] as String,
			profile: _clientProfileFromJson(profileJson),
		);
	}

	ClientProfile _clientProfileFromJson(Map<String, dynamic> profileJson) {
		final reviews = (profileJson['reviews'] as List<dynamic>).map((item) {
			final review = item as Map<String, dynamic>;
			final rating = (review['rating'] as num).toDouble();
			return MasterReview(
				masterName: review['author_name'] as String,
				rating: rating,
				text: review['text'] as String,
				tag: appointmentRatingLabel(rating),
				ratedAt: DateTime(review['review_year'] as int, review['review_month'] as int),
			);
		}).toList();

		return ClientProfile(
			phone: profileJson['phone'] as String,
			ratingLabel: profileJson['rating_label'] as String,
			reviewsAverage: (profileJson['reviews_average'] as num).toDouble(),
			reviewsCount: profileJson['reviews_count'] as int,
			noShowsCount: profileJson['no_shows_count'] as int,
			scandalsCount: profileJson['scandals_count'] as int,
			reviews: reviews,
			reliabilityTitle: profileJson['reliability_title'] as String,
			reliabilitySubtitle: profileJson['reliability_subtitle'] as String,
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
			isClosed: json['is_closed'] as bool? ?? false,
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
			attachmentUrl: json['attachment_url'] as String?,
			attachmentName: json['attachment_name'] as String?,
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

	MasterSettings _masterSettingsFromJson(Map<String, dynamic> json) {
		return MasterSettings(
			pushNotificationsEnabled: json['push_notifications_enabled'] as bool? ?? true,
			emailNotificationsEnabled: json['email_notifications_enabled'] as bool? ?? true,
			marketingNotificationsEnabled:
				json['marketing_notifications_enabled'] as bool? ?? false,
			visitResultDefaultsEnabled:
				json['visit_result_defaults_enabled'] as bool? ?? true,
		);
	}

	YClientsIntegration _yClientsIntegrationFromJson(Map<String, dynamic> json) {
		final lastSyncRaw = json['last_sync_at'] as String?;
		return YClientsIntegration(
			enabled: json['enabled'] as bool? ?? false,
			partnerToken: json['partner_token'] as String? ?? '',
			companyId: json['company_id'] as String? ?? '',
			login: json['login'] as String? ?? '',
			hasUserToken: json['has_user_token'] as bool? ?? false,
			authPending: json['auth_pending'] as bool? ?? false,
			authRecipient: json['auth_recipient'] as String? ?? '',
			syncIntervalMinutes: json['sync_interval_minutes'] as int? ?? 15,
			lastSyncAt: lastSyncRaw == null ? null : DateTime.parse(lastSyncRaw).toLocal(),
			lastSyncCount: json['last_sync_count'] as int? ?? 0,
		);
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

	AppointmentStatus _statusFromApi(String value) {
		return switch (value) {
			'completed' => AppointmentStatus.completed,
			'no_show' => AppointmentStatus.noShow,
			'cancelled' => AppointmentStatus.cancelled,
			_ => AppointmentStatus.scheduled,
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
