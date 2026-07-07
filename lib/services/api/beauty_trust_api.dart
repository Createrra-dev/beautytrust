import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

class ApiException implements Exception {
	ApiException(this.message, {this.statusCode});

	final String message;
	final int? statusCode;

	@override
	String toString() => message;
}

class BeautyTrustApi {
	BeautyTrustApi({http.Client? client}) : _client = client ?? http.Client();

	final http.Client _client;

	Uri _uri(String path, [Map<String, String>? query]) {
		return Uri.parse(AppConfig.apiBaseUrl).replace(
			path: path,
			queryParameters: query,
		);
	}

	Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
		final response = await _client.get(_uri(path, query));
		return _decodeMap(response);
	}

	Future<List<dynamic>> getJsonList(String path, {Map<String, String>? query}) async {
		final response = await _client.get(_uri(path, query));
		return _decodeList(response);
	}

	Future<Map<String, dynamic>> postJson(
		String path, {
		Map<String, dynamic>? body,
	}) async {
		final response = await _client.post(
			_uri(path),
			headers: {'Content-Type': 'application/json'},
			body: jsonEncode(body ?? {}),
		);
		return _decodeMap(response);
	}

	Future<Map<String, dynamic>> patchJson(
		String path, {
		Map<String, dynamic>? body,
	}) async {
		final response = await _client.patch(
			_uri(path),
			headers: {'Content-Type': 'application/json'},
			body: jsonEncode(body ?? {}),
		);
		return _decodeMap(response);
	}

	Map<String, dynamic> _decodeMap(http.Response response) {
		if (response.statusCode >= 200 && response.statusCode < 300) {
			return jsonDecode(response.body) as Map<String, dynamic>;
		}
		throw ApiException(_extractError(response.body), statusCode: response.statusCode);
	}

	List<dynamic> _decodeList(http.Response response) {
		if (response.statusCode >= 200 && response.statusCode < 300) {
			return jsonDecode(response.body) as List<dynamic>;
		}
		throw ApiException(_extractError(response.body), statusCode: response.statusCode);
	}

	String _extractError(String body) {
		try {
			final decoded = jsonDecode(body) as Map<String, dynamic>;
			final detail = decoded['detail'];
			if (detail is String) {
				return detail;
			}
		} catch (_) {}
		return 'Ошибка API';
	}
}
