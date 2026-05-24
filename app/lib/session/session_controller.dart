import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/gateway_json.dart';
import '../config/env.dart';
import 'token_expiry.dart';

const _kAccessKey = 'session_access_token';
const _kRefreshKey = 'session_refresh_token';
// 兼容旧版仅写入了 session_token 的安装
const _kLegacyTokenKey = 'session_token';

/// 会话状态；同时作为 `GoRouter.refreshListenable`。
class SessionController extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;

  /// 兼容旧命名：等同 access token。
  String? get token => _accessToken;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kAccessKey) ?? prefs.getString(_kLegacyTokenKey);
    _refreshToken = prefs.getString(_kRefreshKey);
    notifyListeners();
  }

  Future<void> persistTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await prefs.setString(_kAccessKey, accessToken);
    await prefs.setString(_kRefreshKey, refreshToken);
    await prefs.remove(_kLegacyTokenKey);
    notifyListeners();
  }

  /// 冷启动或 access 将过期时主动 refresh；失败则 [signOut]。
  Future<bool> ensureFreshSession() async {
    final rt = _refreshToken;
    final hasRefresh = rt != null && rt.isNotEmpty;
    if (!isLoggedIn && !hasRefresh) return false;

    if (!hasRefresh) return isLoggedIn;

    if (!accessTokenShouldRefresh(_accessToken)) return isLoggedIn;

    final ok = await trySilentRefresh();
    if (ok) return true;

    if (isLoggedIn) {
      await signOut();
    }
    return false;
  }

  /// 使用 [AppEnv.refreshTokenPath] 与 body `{ refreshToken }` 尝试换新 access（无 path 则 false）。
  Future<bool> trySilentRefresh() async {
    if (AppEnv.refreshTokenPath.isEmpty) return false;
    final rt = _refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final base = AppEnv.apiBaseUrl.endsWith('/')
          ? AppEnv.apiBaseUrl.substring(0, AppEnv.apiBaseUrl.length - 1)
          : AppEnv.apiBaseUrl;
      final path = AppEnv.refreshTokenPath.startsWith('/') ? AppEnv.refreshTokenPath : '/${AppEnv.refreshTokenPath}';
      final uri = Uri.parse('$base$path');
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );
      if (res.statusCode != 200) return false;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final code = map['code'];
      final c = code is int ? code : (code is num ? code.toInt() : -1);
      if (c != 0) return false;
      final data = map['data'];
      if (data is! Map<String, dynamic>) return false;
      final at = readGatewayStr(data, 'accessToken', 'access_token');
      final nr = readGatewayStr(data, 'refreshToken', 'refresh_token') ?? rt;
      if (at == null || at.isEmpty) return false;
      await persistTokens(accessToken: at, refreshToken: nr);
      return true;
    } catch (_) {
      return false;
    }
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
