import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_client.dart';
import '../../api/app_debug_log.dart';
import 'ucg_push_channel.dart';
import 'ucg_push_native.dart';

const _kDeviceKeyStorage = 'ucg_push_device_key';

/// 全局厂商推送 token 注册（push-service：`/app/api/push/*`）。
///
/// 门闸仅为已登录；服务端 JWT wxId 表示登录用户，不要求绑微信。
class UcgPushRegistrationService {
  UcgPushRegistrationService({
    required ApiClient api,
    FlutterSecureStorage? secureStorage,
  })  : _api = api,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _secureStorage;
  StreamSubscription<UcgPushTokenEvent>? _tokenSub;
  UcgPushChannel? _activeChannel;
  UcgPushChannel? _cachedChannel;
  String? _cachedToken;
  String? _cachedDeviceKey;

  Future<String> deviceKey() async {
    final existing = await _secureStorage.read(key: _kDeviceKeyStorage);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final generated = const Uuid().v4();
    await _secureStorage.write(key: _kDeviceKeyStorage, value: generated);
    return generated;
  }

  Future<void> bindTokenRefreshListener(Future<void> Function() onRefresh) async {
    await _tokenSub?.cancel();
    _tokenSub = UcgPushNative.tokenRefreshStream.listen((_) {
      unawaited(onRefresh());
    });
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
  }

  /// Returns detected channel; null on unsupported Android OEM or web.
  Future<UcgPushChannel?> detectSupportedChannel() => UcgPushNative.detectChannel();

  /// 已登录即可注册；不检查微信绑定。
  Future<bool> registerIfEligible({required bool isLoggedIn}) async {
    if (kIsWeb || !isLoggedIn) return false;
    final channel = await detectSupportedChannel();
    if (channel == null) return false;
    await UcgPushNative.requestNotificationPermission();
    final token = await UcgPushNative.fetchToken(channel);
    if (token == null || token.isEmpty) return false;
    final key = await deviceKey();
    if (_matchesCachedRegistration(channel, token, key)) {
      _activeChannel = channel;
      AppDebugLog.ucgPush('register skip cached channel=${channel.apiValue}');
      return true;
    }
    _activeChannel = channel;
    // 全局 push-service（非 /ucg/app/api）
    await _api.postJsonEnvelope('/app/api/push/register', {
      'channel': channel.apiValue,
      'token': token,
      'deviceKey': key,
    });
    _cachedChannel = channel;
    _cachedToken = token;
    _cachedDeviceKey = key;
    AppDebugLog.ucgPush('register ok channel=${channel.apiValue}');
    return true;
  }

  Future<void> unregister() async {
    if (kIsWeb) return;
    final key = await deviceKey();
    final body = <String, dynamic>{'deviceKey': key};
    final ch = _activeChannel;
    if (ch != null) {
      body['channel'] = ch.apiValue;
    }
    try {
      await _api.postJsonEnvelope('/app/api/push/unregister', body);
    } catch (e) {
      AppDebugLog.ucgPush('unregister err=$e');
    }
    _activeChannel = null;
    _clearRegistrationCache();
  }

  bool _matchesCachedRegistration(UcgPushChannel channel, String token, String deviceKey) {
    return _cachedChannel == channel &&
        _cachedToken == token &&
        _cachedDeviceKey == deviceKey;
  }

  void _clearRegistrationCache() {
    _cachedChannel = null;
    _cachedToken = null;
    _cachedDeviceKey = null;
  }
}
