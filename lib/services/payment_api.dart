import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

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

	Future<PaymentInitResult> initPayment() async {
		final response = await _client.post(
			_baseUri.replace(path: '/api/payments/init'),
			headers: {'Content-Type': 'application/json'},
			body: jsonEncode({
				'return_base_url': AppConfig.apiBaseUrl,
			}),
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
