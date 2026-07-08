import '../../models/otp_delivery_channel.dart';
import 'beauty_trust_api.dart';

class OtpSendResult {
	const OtpSendResult({
		required this.sessionId,
		required this.botUrl,
		required this.botUsername,
		required this.codeSent,
		required this.expiresIn,
		required this.channel,
	});

	final String sessionId;
	final String botUrl;
	final String botUsername;
	final bool codeSent;
	final int expiresIn;
	final OtpDeliveryChannel channel;

	factory OtpSendResult.fromJson(Map<String, dynamic> json) {
		return OtpSendResult(
			sessionId: json['session_id'] as String,
			botUrl: json['bot_url'] as String,
			botUsername: json['bot_username'] as String,
			codeSent: json['code_sent'] as bool? ?? false,
			expiresIn: json['expires_in'] as int? ?? 300,
			channel: OtpDeliveryChannel.fromApiValue(json['channel'] as String? ?? 'telegram'),
		);
	}
}

class OtpCallStatusResult {
	const OtpCallStatusResult({
		required this.sessionId,
		required this.channel,
		this.callId,
		this.callStatus,
		this.callStatusDisplay,
		this.dialStatusDisplay,
		this.completed = false,
	});

	final String sessionId;
	final String channel;
	final int? callId;
	final String? callStatus;
	final String? callStatusDisplay;
	final String? dialStatusDisplay;
	final bool completed;

	factory OtpCallStatusResult.fromJson(Map<String, dynamic> json) {
		return OtpCallStatusResult(
			sessionId: json['session_id'] as String,
			channel: json['channel'] as String,
			callId: json['call_id'] as int?,
			callStatus: json['call_status'] as String?,
			callStatusDisplay: json['call_status_display'] as String?,
			dialStatusDisplay: json['dial_status_display'] as String?,
			completed: json['completed'] as bool? ?? false,
		);
	}
}

class AuthTokenResult {
	const AuthTokenResult({
		required this.accessToken,
		required this.masterId,
		required this.isNewUser,
	});

	final String accessToken;
	final int masterId;
	final bool isNewUser;

	factory AuthTokenResult.fromJson(Map<String, dynamic> json) {
		return AuthTokenResult(
			accessToken: json['access_token'] as String,
			masterId: json['master_id'] as int,
			isNewUser: json['is_new_user'] as bool? ?? false,
		);
	}
}

class AuthApi {
	AuthApi({BeautyTrustApi? api}) : _api = api ?? BeautyTrustApi();

	final BeautyTrustApi _api;

	Future<OtpSendResult> sendOtp(
		String phoneDigits, {
		OtpDeliveryChannel channel = OtpDeliveryChannel.telegram,
		bool isRegistration = false,
	}) async {
		final json = await _api.postJson(
			'/api/auth/otp/send',
			body: {
				'phone': '+7$phoneDigits',
				'channel': channel.apiValue,
				'is_registration': isRegistration,
			},
		);
		return OtpSendResult.fromJson(json);
	}

	Future<AuthTokenResult> verifyOtp({
		required String sessionId,
		required String code,
		String? phoneDigits,
		String? firstName,
	}) async {
		final json = await _api.postJson(
			'/api/auth/otp/verify',
			body: {
				'session_id': sessionId,
				'code': code,
				if (phoneDigits != null) 'phone': '+7$phoneDigits',
				if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
			},
		);
		return AuthTokenResult.fromJson(json);
	}

	Future<bool> isPhoneRegistered(String phoneDigits) async {
		final json = await _api.postJson(
			'/api/auth/phone/check',
			body: {'phone': '+7$phoneDigits'},
		);
		return json['registered'] as bool? ?? false;
	}

	Future<OtpCallStatusResult> fetchCallStatus(String sessionId) async {
		final json = await _api.getJson(
			'/api/auth/otp/call-status',
			query: {'session_id': sessionId},
		);
		return OtpCallStatusResult.fromJson(json);
	}
}
