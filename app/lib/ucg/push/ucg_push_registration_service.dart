import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../data/ucg_api_client.dart';
import 'ucg_push_channel.dart';
import 'ucg_push_native.dart';

const _kDeviceKeyStorage = 'ucg_push_device_key';

/// Registers vendor push tokens with ucg-service when wxId is bound.
class UcgPushRegistrationService {
  UcgPushRegistrationService({
    required UcgApiClient api,
    FlutterSecureStorage? secureStorage,
  })  : _api = api,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final UcgApiClient _api;
  final FlutterSecureStorage _secureStorage;
  StreamSubscription<UcgPushTokenEvent>? _tokenSub;
  UcgPushChannel? _activeChannel;

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

  Future<bool> registerIfEligible({
    required bool isLoggedIn,
    required bool wxBound,
  }) async {
    if (kIsWeb || !isLoggedIn || !wxBound) return false;
    final channel = await detectSupportedChannel();
    if (channel == null) {
      debugPrint('[ucg-push] skip register: unsupported OEM');
      return false;
    }
    await UcgPushNative.requestNotificationPermission();
    final token = await UcgPushNative.fetchToken(channel);
    if (token == null || token.isEmpty) {
      debugPrint('[ucg-push] skip register: no token for ${channel.apiValue}');
      return false;
    }
    _activeChannel = channel;
    final key = await deviceKey();
    await _api.post('/push/register', {
      'channel': channel.apiValue,
      'token': token,
      'deviceKey': key,
    });
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
      await _api.post('/push/unregister', body);
    } catch (_) {}
    _activeChannel = null;
  }
}
