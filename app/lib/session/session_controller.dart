import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../api/gateway_json.dart';
import '../config/env.dart';
import 'token_expiry.dart';

const _kAccessKey = 'session_access_token';
const _kRefreshKey = 'session_refresh_token';
// 兼容旧版仅写入了 session_token 的安装
const _kLegacyTokenKey = 'session_token';

/// refresh 尝试结果：成功、可重试的瞬时失败、refresh 明确无效。
enum _RefreshOutcome {
  success,
  transientFailure,
  invalidRefresh,
}

/// 会话状态；同时作为 `GoRouter.refreshListenable`。
class SessionController extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;

  /// 并发 refresh 单飞：同一时刻仅一次 POST /token/refresh。
  Future<bool>? _refreshInFlight;
  _RefreshOutcome? _lastRefreshOutcome;

  /// 兼容旧命名：等同 access token。
  String? get token => _accessToken;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  /// 静默 refresh 单飞进行中（供 WS 横幅等 UI 抑制误报断连）。
  bool get isRefreshInFlight => _refreshInFlight != null;

  /// refresh 失败后是否应硬登出：access 仍须续期且上次为 refresh 明确无效。
  bool get shouldHardSignOutAfterRefreshFailure {
    if (!accessTokenShouldRefresh(_accessToken)) return false;
    return _lastRefreshOutcome == _RefreshOutcome.invalidRefresh;
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kAccessKey) ?? prefs.getString(_kLegacyTokenKey);
    _refreshToken = prefs.getString(_kRefreshKey);
    notifyListeners();
  }

  /// 写入 access/refresh token。若新旧 access 均非空且不同，视为 **token 轮换**（非登出）。
  /// 监听方可用 [isAccessTokenRotation] 判断；[signOut] 清空 token 不视为轮换。
  Future<void> persistTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await prefs.setString(_kAccessKey, accessToken);
    await prefs.setString(_kRefreshKey, refreshToken);
    await prefs.remove(_kLegacyTokenKey);
    notifyListeners();
  }

  /// 非空 access 被替换为不同非空 access（登录初写与 [signOut] 除外）。
  static bool isAccessTokenRotation(String? previous, String? next) {
    if (next == null || next.isEmpty) return false;
    if (previous == null || previous.isEmpty) return false;
    return previous != next;
  }

  /// 冷启动或 access 将过期时主动 refresh；明确 refresh 无效时 [signOut]。
  Future<bool> ensureFreshSession() async {
    final rt = _refreshToken;
    final hasRefresh = rt != null && rt.isNotEmpty;
    if (!isLoggedIn && !hasRefresh) return false;

    if (!hasRefresh) return isLoggedIn;

    if (!accessTokenShouldRefresh(_accessToken)) return isLoggedIn;

    final ok = await _runRefreshDeduped();
    if (ok) return true;

    // 竞态：并发 refresh 赢家已写入新 token；或网络瞬时失败保留会话。
    if (!shouldHardSignOutAfterRefreshFailure) {
      return !accessTokenShouldRefresh(_accessToken) && isLoggedIn;
    }

    if (isLoggedIn) {
      await signOut();
    }
    return false;
  }

  /// 绑定宝宝或 WS 建连前对齐 JWT `device_no`：无条件 refresh（不受过期 buffer 限制）。
  Future<bool> refreshSessionForDeviceBind() async {
    if (!isLoggedIn) return false;
    return _runRefreshDeduped();
  }

  /// 使用 [AppEnv.refreshTokenPath] 与 body `{ refreshToken }` 尝试换新 access（无 path 则 false）。
  Future<bool> trySilentRefresh() async => _runRefreshDeduped();

  Future<bool> _runRefreshDeduped() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _performSilentRefresh().then((outcome) {
      _lastRefreshOutcome = outcome;
      return outcome == _RefreshOutcome.success;
    });
    _refreshInFlight = future;
    notifyListeners();
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
        notifyListeners();
      }
    }
  }

  Future<_RefreshOutcome> _performSilentRefresh() async {
    if (AppEnv.refreshTokenPath.isEmpty) return _RefreshOutcome.invalidRefresh;
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return _RefreshOutcome.invalidRefresh;
    }

    const maxAttempts = 3;
    const retryDelays = [
      Duration(milliseconds: 300),
      Duration(milliseconds: 800),
    ];

    _RefreshOutcome lastOutcome = _RefreshOutcome.transientFailure;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(retryDelays[attempt - 1]);
        if (!accessTokenShouldRefresh(_accessToken)) {
          return _RefreshOutcome.success;
        }
      }

      lastOutcome = await _refreshTokenHttpOnce();
      if (lastOutcome == _RefreshOutcome.success) return _RefreshOutcome.success;
      if (lastOutcome == _RefreshOutcome.invalidRefresh) return _RefreshOutcome.invalidRefresh;
    }

    if (!accessTokenShouldRefresh(_accessToken)) return _RefreshOutcome.success;
    return lastOutcome;
  }

  Future<_RefreshOutcome> _refreshTokenHttpOnce() async {
    final rt = _refreshToken;
    if (rt == null || rt.isEmpty) return _RefreshOutcome.invalidRefresh;

    try {
      final base = AppEnv.apiBaseUrl.endsWith('/')
          ? AppEnv.apiBaseUrl.substring(0, AppEnv.apiBaseUrl.length - 1)
          : AppEnv.apiBaseUrl;
      final path =
          AppEnv.refreshTokenPath.startsWith('/') ? AppEnv.refreshTokenPath : '/${AppEnv.refreshTokenPath}';
      final uri = Uri.parse('$base$path');
      // Web 上 inline Map  literal 传入 http.post 可能触发 LegacyJavaScriptObject；用 Request 逐条设 header。
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'refreshToken': rt});
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 500) return _RefreshOutcome.transientFailure;

      if (res.statusCode == 401) {
        return _RefreshOutcome.invalidRefresh;
      }

      if (res.statusCode != 200) {
        if (res.statusCode >= 400 && res.statusCode < 500) {
          return _parseRefreshFailureOutcome(res);
        }
        return _RefreshOutcome.transientFailure;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return _RefreshOutcome.transientFailure;
      final map = decoded;

      final codeVal = map['code'];
      final code = codeVal is int ? codeVal : (codeVal is num ? codeVal.toInt() : -1);
      if (code != 0) {
        return _isExplicitRefreshInvalid(map, res.statusCode)
            ? _RefreshOutcome.invalidRefresh
            : _RefreshOutcome.transientFailure;
      }

      final data = map['data'];
      if (data is! Map<String, dynamic>) return _RefreshOutcome.transientFailure;
      final at = readGatewayStr(data, 'accessToken', 'access_token');
      final nr = readGatewayStr(data, 'refreshToken', 'refresh_token') ?? rt;
      if (at == null || at.isEmpty) return _RefreshOutcome.transientFailure;
      await persistTokens(accessToken: at, refreshToken: nr);
      return _RefreshOutcome.success;
    } on SocketException {
      return _RefreshOutcome.transientFailure;
    } on TimeoutException {
      return _RefreshOutcome.transientFailure;
    } on IOException {
      return _RefreshOutcome.transientFailure;
    } catch (e) {
      AppDebugLog.wsTransport('token refresh err=$e');
      return _RefreshOutcome.transientFailure;
    }
  }

  _RefreshOutcome _parseRefreshFailureOutcome(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return _isExplicitRefreshInvalid(decoded, res.statusCode)
            ? _RefreshOutcome.invalidRefresh
            : _RefreshOutcome.transientFailure;
      }
    } catch (_) {}
    return _RefreshOutcome.transientFailure;
  }

  /// 解析网关 refresh 失败是否为 refresh 令牌明确无效/过期（非网络抖动）。
  bool _isExplicitRefreshInvalid(Map<String, dynamic> map, int statusCode) {
    if (statusCode == 401) return true;

    final codeVal = map['code'];
    final code = codeVal is int ? codeVal : (codeVal is num ? codeVal.toInt() : -1);
    if (code == 401) return true;

    final message = (map['message'] as String? ?? '').toLowerCase();
    if (message.isEmpty) return false;

    final mentionsRefresh = message.contains('refresh');
    if (mentionsRefresh &&
        (message.contains('无效') ||
            message.contains('过期') ||
            message.contains('invalid') ||
            message.contains('expired'))) {
      return true;
    }
    if (message.contains('refreshtoken') &&
        (message.contains('无效') ||
            message.contains('过期') ||
            message.contains('invalid') ||
            message.contains('expired') ||
            message.contains('empty') ||
            message.contains('空'))) {
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = null;
    _refreshToken = null;
    await prefs.remove(_kAccessKey);
    await prefs.remove(_kRefreshKey);
    await prefs.remove(_kLegacyTokenKey);
    notifyListeners();
  }
}
