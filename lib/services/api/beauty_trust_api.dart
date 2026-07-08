import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../auth_session.dart';

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

	Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
		final response = await _client.get(_uri(path, query), headers: _headers());
		return _decodeMap(response);
	}

	Future<List<dynamic>> getJsonList(String path, {Map<String, String>? query}) async {
		final response = await _client.get(_uri(path, query), headers: _headers());
		return _decodeList(response);
	}

	Future<Map<String, dynamic>> postJson(
		String path, {
		Map<String, dynamic>? body,
	}) async {
		final response = await _client.post(
			_uri(path),
			headers: _headers(jsonBody: true),
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
			headers: _headers(jsonBody: true),
			body: jsonEncode(body ?? {}),
		);
		return _decodeMap(response);
	}

	Future<Map<String, dynamic>> deleteJson(String path) async {
		final response = await _client.delete(_uri(path), headers: _headers());
		if (response.statusCode >= 200 && response.statusCode < 300) {
			if (response.body.isEmpty) {
				return {'ok': true};
			}
			final decoded = jsonDecode(response.body);
			if (decoded is Map<String, dynamic>) {
				return decoded;
			}
			return {'ok': true};
		}
		throw ApiException(_extractError(response.body), statusCode: response.statusCode);
	}

	Future<Map<String, dynamic>> multipartPost(
		String path, {
		required String fieldName,
		required String filePath,
		String? filename,
	}) async {
		final request = http.MultipartRequest('POST', _uri(path));
		request.headers.addAll(_headers());
		request.files.add(
			await http.MultipartFile.fromPath(
				fieldName,
				filePath,
				filename: filename,
			),
		);

		final streamed = await _client.send(request);
		final response = await http.Response.fromStream(streamed);
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
			final message = decoded['message'];
			if (message is String && message.isNotEmpty) {
				return message;
			}
			final detail = decoded['detail'];
			if (detail is String) {
				return detail;
			}
		} catch (_) {}
		return 'Ошибка API';
	}
}
