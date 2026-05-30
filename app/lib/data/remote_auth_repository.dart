import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import '../config/env.dart';
import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../providers/sign_in_channel_provider.dart';
import '../wechat/wechat_auth_client.dart';
import '../wechat/wechat_auth_exception.dart';
import 'repositories.dart' show AuthRepository;

/// 网关 `POST /device/app/api/login`；请求体字段 `jsCode`（微信临时 code）来自 [weChatAuthGetter]、`WX_LOGIN_CODE` 或 [wxCodeOverride]。
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(
    this._ref, {
    String? wxCodeOverride,
    WeChatAuthClient? Function()? weChatAuthGetter,
  })  : _wxCodeOverride = wxCodeOverride,
        _weChatAuthGetter = weChatAuthGetter;

  final Ref _ref;
  final String? _wxCodeOverride;
  final WeChatAuthClient? Function()? _weChatAuthGetter;

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
  }

  ApiClient get _anon => ApiClient(
        baseUrl: AppEnv.apiBaseUrl,
        accessTokenProvider: () => null,
      );

  @override
  Future<void> signInWithWeChat() async {
    String? wxCode = _wxCodeOverride;
    if (wxCode == null || wxCode.isEmpty) {
      final client = _weChatAuthGetter?.call();
      if (client != null) {
        try {
          wxCode = await client.obtainWxCode();
        } on WeChatAuthCanceledException catch (e) {
          throw ApiBusinessException(-1, e.message);
        } on WeChatAuthException catch (e) {
          throw ApiBusinessException(-1, e.message);
        }
      }
    }
    if (wxCode == null || wxCode.isEmpty) {
      wxCode = AppEnv.wxLoginCode;
    }
    if (wxCode.isEmpty) {
      throw ApiBusinessException(
        -1,
        '缺少微信登录凭证：请配置 WECHAT_APP_ID 并安装微信，或配置网页授权参数，或使用 --dart-define=WX_LOGIN_CODE 联调',
      );
    }
    final data = await _anon.postJsonEnvelope(
      '/device/app/api/login',
      {'jsCode': wxCode, 'platform': _platform},
      withAuthorization: false,
    );
    await _persistLoginData(data);
    await _ref.read(signInChannelProvider.notifier).setWechat();
  }

  Future<void> _persistLoginData(Map<String, dynamic>? data) async {
    if (data == null) {
      throw ApiBusinessException(-1, '登录成功但 data 为空');
    }
    final at = readGatewayStr(data, 'accessToken', 'access_token');
    final rt = readGatewayStr(data, 'refreshToken', 'refresh_token');
    if (at == null || at.isEmpty) {
      throw ApiBusinessException(-1, '登录响应缺少 accessToken');
    }
    if (rt == null || rt.isEmpty) {
      throw ApiBusinessException(-1, '登录响应缺少 refreshToken');
    }
    await _ref.read(sessionProvider).persistTokens(accessToken: at, refreshToken: rt);
    final dn = readGatewayStr(data, 'deviceNo', 'device_no');
    final n = _ref.read(deviceNoNotifierProvider.notifier);
    if (dn != null && dn.isNotEmpty) {
      await n.setLocal(dn);
    } else {
      await n.clearLocal();
    }
  }

  @override
  Future<void> signOut() async {}
}
