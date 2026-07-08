import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session.dart';

class PaymentInitResult {
	const PaymentInitResult({
		required this.paymentId,
		required this.paymentUrl,
		required this.orderId,
		required this.amount,
	});

	final String paymentId;
	final String paymentUrl;
	final String orderId;
	final int amount;

	factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
		return PaymentInitResult(
			paymentId: json['payment_id'] as String,
			paymentUrl: json['payment_url'] as String,
			orderId: json['order_id'] as String,
			amount: json['amount'] as int,
		);
	}
}

class PaymentStatusResult {
	const PaymentStatusResult({
		required this.paymentId,
		required this.status,
		required this.success,
		this.orderId,
		this.amount,
	});

	final String paymentId;
	final String status;
	final bool success;
	final String? orderId;
	final int? amount;

	factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
		return PaymentStatusResult(
			paymentId: json['payment_id'] as String,
			status: json['status'] as String,
			success: json['success'] as bool,
			orderId: json['order_id'] as String?,
			amount: json['amount'] as int?,
		);
	}
}

class PaymentApiException implements Exception {
	PaymentApiException(this.message, {this.statusCode});

	final String message;
	final int? statusCode;

	@override
	String toString() => message;
}

class PaymentApi {
	PaymentApi({http.Client? client}) : _client = client ?? http.Client();

	final http.Client _client;

	Uri get _baseUri => Uri.parse(AppConfig.apiBaseUrl);

	Map<String, String> _headers({bool jsonBody = false}) {
		final headers = <String, String>{};
		if (jsonBody) {
			headers['Content-Type'] = 'application/json';
		}

		final token = AuthSession.accessToken;
		if (token != null && token.isNotEmpty) {
			headers['Authorization'] = 'Bearer $token';
		}

		return headers;
	}

	Future<PaymentInitResult> initPayment({
		int? amountKopecks,
		String? description,
		String? returnBaseUrl,
	}) async {
		final body = <String, dynamic>{
			'return_base_url': returnBaseUrl ?? AppConfig.apiBaseUrl,
		};

		if (amountKopecks != null) {
			body['amount'] = amountKopecks;
		}

		if (description != null) {
			body['description'] = description;
		}

		final response = await _client.post(
			_baseUri.replace(path: '/api/payments/init'),
			headers: _headers(jsonBody: true),
			body: jsonEncode(body),
		);

		if (response.statusCode >= 200 && response.statusCode < 300) {
			return PaymentInitResult.fromJson(
				jsonDecode(response.body) as Map<String, dynamic>,
			);
		}

		throw PaymentApiException(
			_extractErrorMessage(response.body),
			statusCode: response.statusCode,
		);
	}

	Future<PaymentStatusResult> getPaymentStatus(String paymentId) async {
		final response = await _client.get(
			_baseUri.replace(path: '/api/payments/$paymentId/status'),
			headers: _headers(),
		);

		if (response.statusCode >= 200 && response.statusCode < 300) {
			return PaymentStatusResult.fromJson(
				jsonDecode(response.body) as Map<String, dynamic>,
			);
		}

		throw PaymentApiException(
			_extractErrorMessage(response.body),
			statusCode: response.statusCode,
		);
	}

	String _extractErrorMessage(String body) {
		try {
			final decoded = jsonDecode(body) as Map<String, dynamic>;
			final message = decoded['message'];
			if (message is String && message.isNotEmpty) {
				return message;
			}
			final detail = decoded['detail'];
			if (detail is String) {
				return detail;
			}
		} catch (_) {
			// Ignore JSON parsing errors.
		}

		return 'Ошибка API (${body.isEmpty ? 'пустой ответ' : body})';
	}
}
