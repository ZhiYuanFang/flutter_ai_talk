import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:pangbao_app/home_widget/home_widget_payload.dart';

/// Debug 下 ApiClient HTTP 请求/响应 console 日志（脱敏）。
abstract final class ApiHttpLog {
  static const _bodyPreviewMax = 2048;

  static const _redactKeys = {
    'authorization',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'password',
    'identitytoken',
    'identity_token',
    'jscode',
    'js_code',
    'token',
  };

  static String _ts() => HomeWidgetRowPayload .isoUtc(DateTime.now());

  static void request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  }) {
    if (!kDebugMode) return;
    final headerPart = _formatHeaders(headers);
    final bodyPart = body == null || body.isEmpty ? '' : ' body=${_redactBody(body)}';
    debugPrint('[ApiHttp] ${_ts()} -> $method $uri$headerPart$bodyPart');
  }

  static void response({
    required int status,
    required int elapsedMs,
    String? body,
    bool retried = false,
  }) {
    if (!kDebugMode) return;
    final retry = retried ? ' retry' : '';
    final bodyPart = body == null || body.isEmpty ? '' : ' body=${_preview(body)}';
    debugPrint('[ApiHttp] ${_ts()} <- $status ${elapsedMs}ms$retry$bodyPart');
  }

  static void retryAfter401() {
    if (!kDebugMode) return;
    debugPrint('[ApiHttp] ${_ts()} retry after 401');
  }

  static String _formatHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return '';
    final parts = <String>[];
    for (final e in headers.entries) {
      if (e.key.toLowerCase() == 'authorization') {
        parts.add('${e.key}=Bearer ***');
      } else {
        parts.add('${e.key}=${e.value}');
      }
    }
    return ' headers={${parts.join(', ')}}';
  }

  static String _redactBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return jsonEncode(_redactValue(decoded));
    } catch (_) {
      return _preview(body);
    }
  }

  static dynamic _redactValue(dynamic value) {
    if (value is Map) {
      return {
        for (final e in value.entries)
          e.key: _redactKey(e.key.toString(), e.value),
      };
    }
    if (value is List) {
      return value.map(_redactValue).toList();
    }
    return value;
  }

  static dynamic _redactKey(String key, dynamic value) {
    final normalized = key.toLowerCase().replaceAll('-', '_');
    if (_redactKeys.contains(normalized)) return '***';
    return _redactValue(value);
  }

  static String _preview(String s) {
    if (s.length <= _bodyPreviewMax) return s;
    return '${s.substring(0, _bodyPreviewMax)}…(${s.length} chars)';
  }
}
