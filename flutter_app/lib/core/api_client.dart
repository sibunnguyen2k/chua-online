import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'auth_token';

  String? get token => _prefs.getString(_key);
  Future<void> save(String token) => _prefs.setString(_key, token);
  Future<void> clear() => _prefs.remove(_key);
}

class ApiException implements Exception {
  const ApiException(this.code, {this.status});

  final String code;
  final int? status;

  bool get isUnauthorized => status == 401;

  static const _messages = <String, String>{
    'daily_limit_reached': 'Hôm nay bạn đã đạt giới hạn cho việc này.',
    'already_checked_in': 'Hôm nay bạn đã điểm danh rồi.',
    'quest_not_completed': 'Nhiệm vụ chưa hoàn thành.',
    'quest_already_claimed': 'Bạn đã nhận thưởng nhiệm vụ này.',
    'invalid_name': 'Pháp danh cần từ 2 đến 40 ký tự.',
    'invalid_content': 'Nội dung cần từ 1 đến 300 ký tự.',
    'network': 'Không thể kết nối máy chủ.',
    'timeout': 'Hết thời gian chờ, vui lòng thử lại.',
  };

  String get message => _messages[code] ?? 'Đã có lỗi xảy ra ($code).';

  @override
  String toString() => message;
}

/// HTTP client mỏng: gắn Bearer token, parse JSON, quy đổi lỗi về ApiException.
class ApiClient {
  ApiClient({required this.baseUrl, required this.tokens, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;

  bool get hasToken => tokens.token != null;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path,
          {Object? body, bool auth = true}) =>
      _send('POST', path, body: body ?? const {}, auth: auth);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body ?? const {});

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async {
    final uri =
        Uri.parse('$baseUrl/api/v1$path').replace(queryParameters: query);
    final req = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    final token = tokens.token;
    if (auth && token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(req).timeout(const Duration(seconds: 15)),
      );
    } on TimeoutException {
      throw const ApiException('timeout');
    } on http.ClientException {
      throw const ApiException('network');
    }

    Map<String, dynamic> json = const {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    throw ApiException(json['error'] as String? ?? 'http_${res.statusCode}',
        status: res.statusCode);
  }

  void dispose() => _client.close();
}
