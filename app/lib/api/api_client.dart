import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exceptions.dart';
import 'api_http_log.dart';
import 'gateway_user_message.dart';

typedef AccessTokenProvider = String? Function();
typedef UnauthorizedRefresh = Future<bool> Function();
typedef UnauthorizedFailed = Future<void> Function();

/// 解析 `{ code, message, data }`；HTTP 期望 **200**；`code != 0` 抛 [ApiBusinessException]。
///
/// 带鉴权请求若返回 **401**，先调用 [onUnauthorizedRefresh]；成功则 **重试一次** 原请求；
/// 刷新失败则调用 [onUnauthorizedFailed]（例如登出），再按非 200 抛 [ApiHttpException]。
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.onUnauthorizedRefresh,
    this.onUnauthorizedFailed,
  });

  final String baseUrl;
  final AccessTokenProvider accessTokenProvider;
  final UnauthorizedRefresh? onUnauthorizedRefresh;
  final UnauthorizedFailed? onUnauthorizedFailed;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    final rel = path.startsWith('/') ? path : '/$path';
    final mergedPath = '${base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path}$rel';
    return base.replace(path: mergedPath, queryParameters: query);
  }

  Map<String, String> _headers({bool withAuthorization = true}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withAuthorization) {
      final t = accessTokenProvider();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  /// [withAuthorization] 为 `false` 时不带 Bearer（如登录、刷新、版本检查等网关约定）。
  /// [timeout] 可选；未设则使用 HTTP 包默认（无上限）。推荐 Feed 索引 warm 场景建议 ≥45s。
  Future<Map<String, dynamic>?> getEnvelope(
    String path, {
    Map<String, String>? query,
    bool withAuthorization = true,
    Duration? timeout,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(withAuthorization: withAuthorization);
    final res = await _send(
      () => http.get(uri, headers: headers),
      method: 'GET',
      uri: uri,
      headers: headers,
      withAuthorization: withAuthorization,
      timeout: timeout,
    );
    return _decodeResponse(res);
  }

  Future<Map<String, dynamic>?> postJsonEnvelope(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
    bool withAuthorization = true,
  }) async {
    final uri = _uri(path, query);
    final encoded = jsonEncode(body);
    final headers = _headers(withAuthorization: withAuthorization);
    final res = await _send(
      () => http.post(
            uri,
            headers: headers,
            body: encoded,
          ),
      method: 'POST',
      uri: uri,
      headers: headers,
      requestBody: encoded,
      withAuthorization: withAuthorization,
    );
    return _decodeResponse(res);
  }

  Future<Map<String, dynamic>?> putJsonEnvelope(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
    bool withAuthorization = true,
  }) async {
    final uri = _uri(path, query);
    final encoded = jsonEncode(body);
    final headers = _headers(withAuthorization: withAuthorization);
    final res = await _send(
      () => http.put(
            uri,
            headers: headers,
            body: encoded,
          ),
      method: 'PUT',
      uri: uri,
      headers: headers,
      requestBody: encoded,
      withAuthorization: withAuthorization,
    );
    return _decodeResponse(res);
  }

  Future<Map<String, dynamic>?> deleteEnvelope(
    String path, {
    Map<String, String>? query,
    bool withAuthorization = true,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(withAuthorization: withAuthorization);
    final res = await _send(
      () => http.delete(uri, headers: headers),
      method: 'DELETE',
      uri: uri,
      headers: headers,
      withAuthorization: withAuthorization,
    );
    return _decodeResponse(res);
  }

  /// multipart/form-data POST；用于 UCG Web 媒体同域代理上传等场景。
  Future<Map<String, dynamic>?> postMultipartEnvelope(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String fileName,
    required List<int> bytes,
    Map<String, String>? query,
    bool withAuthorization = true,
  }) async {
    final uri = _uri(path, query);
    Future<http.Response> send() async {
      final req = http.MultipartRequest('POST', uri);
      if (withAuthorization) {
        final t = accessTokenProvider();
        if (t != null && t.isNotEmpty) {
          req.headers['Authorization'] = 'Bearer $t';
        }
      }
      req.fields.addAll(fields);
      req.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: fileName));
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    final res = await _send(
      send,
      method: 'POST',
      uri: uri,
      headers: withAuthorization ? _headers(withAuthorization: true) : const {'Content-Type': 'multipart/form-data'},
      requestBody: 'multipart file=$fileField name=$fileName bytes=${bytes.length}',
      withAuthorization: withAuthorization,
    );
    return _decodeResponse(res);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() once, {
    required String method,
    required Uri uri,
    required Map<String, String>? headers,
    String? requestBody,
    required bool withAuthorization,
    Duration? timeout,
  }) async {
    final sw = Stopwatch()..start();
    ApiHttpLog.request(
      method: method,
      uri: uri,
      headers: headers,
      body: requestBody,
    );

    Future<http.Response> run() {
      final f = once();
      return timeout != null ? f.timeout(timeout) : f;
    }

    var retried = false;
    var res = await run();
    if (res.statusCode == 401 && withAuthorization) {
      final refresh = onUnauthorizedRefresh;
      if (refresh != null) {
        final ok = await refresh();
        if (ok) {
          ApiHttpLog.retryAfter401();
          retried = true;
          sw.reset();
          sw.start();
          res = await run();
        } else {
          await onUnauthorizedFailed?.call();
        }
      }
    }

    ApiHttpLog.response(
      status: res.statusCode,
      elapsedMs: sw.elapsedMilliseconds,
      body: res.body,
      retried: retried,
    );
    return res;
  }

  Future<Map<String, dynamic>?> _decodeResponse(http.Response res) async {
    if (res.statusCode != 200) {
      throw ApiHttpException(res.statusCode, res.body);
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiBusinessException(-1, '响应格式错误');
    }
    final codeVal = decoded['code'];
    final code = codeVal is int ? codeVal : (codeVal is num ? codeVal.toInt() : -1);
    final message = decoded['message'] as String? ?? '';
    if (code != 0) {
      final userMessage = message.isEmpty ? '业务失败($code)' : message;
      throw ApiBusinessException(code, normalizeUserFacingApiMessage(userMessage));
    }
    final data = decoded['data'];
    if (data == null) return null;
    if (data is! Map<String, dynamic>) {
      return {'_primitive': data};
    }
    return data;
  }
}
