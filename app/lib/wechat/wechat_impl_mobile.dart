import 'dart:async';
import 'dart:math';

import 'package:fluwx/fluwx.dart';

import '../config/env.dart';
import 'wechat_auth_client.dart';
import 'wechat_auth_exception.dart';

/// Android / iOS：通过 fluwx 拉起微信并获取 `code`。
class FluwxMobileWeChatAuthClient implements WeChatAuthClient {
  FluwxMobileWeChatAuthClient({
    required this.appId,
    required this.universalLink,
  });

  final String appId;
  final String? universalLink;

  static final Fluwx _fluwx = Fluwx();
  static var _registered = false;

  Future<void> _ensureRegistered() async {
    if (_registered) return;
    final ok = await _fluwx.registerApi(
      appId: appId,
      universalLink: universalLink?.isEmpty ?? true ? null : universalLink,
    );
    if (!ok) {
      throw WeChatAuthException('微信 SDK 注册失败，请检查 WECHAT_APP_ID 与 universal link');
    }
    _registered = true;
  }

  @override
  Future<String> obtainWxCode() async {
    await _ensureRegistered();
    if (!await _fluwx.isWeChatInstalled) {
      throw WeChatAuthException('未安装微信');
    }
    final state = List.generate(32, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
    final completer = Completer<String>();
    FluwxCancelable? cancelable;
    cancelable = _fluwx.addSubscriber((WeChatResponse response) {
      if (response is! WeChatAuthResponse) return;
      cancelable?.cancel();
      final auth = response;
      if (auth.isSuccessful && auth.code != null && auth.code!.isNotEmpty) {
        if (!completer.isCompleted) completer.complete(auth.code!);
        return;
      }
      final ec = auth.errCode;
      if (ec == -2) {
        if (!completer.isCompleted) completer.completeError(WeChatAuthCanceledException());
      } else {
        if (!completer.isCompleted) {
          completer.completeError(
            WeChatAuthException(auth.errStr ?? '微信授权失败(${auth.errCode})'),
          );
        }
      }
    });
    final launched = await _fluwx.authBy(which: NormalAuth(scope: 'snsapi_userinfo', state: state));
    if (!launched) {
      cancelable.cancel();
      throw WeChatAuthException('无法拉起微信授权');
    }
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        cancelable?.cancel();
        throw WeChatAuthException('微信授权超时');
      },
    );
  }
}

/// VM / iOS / Android：使用 fluwx。
WeChatAuthClient? createWeChatAuthClient() {
  if (AppEnv.wechatAppId.isEmpty) return null;
  return FluwxMobileWeChatAuthClient(
    appId: AppEnv.wechatAppId,
    universalLink: AppEnv.wechatUniversalLink.isEmpty ? null : AppEnv.wechatUniversalLink,
  );
}
