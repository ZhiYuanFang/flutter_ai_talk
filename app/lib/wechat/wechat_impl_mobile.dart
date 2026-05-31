import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:fluwx/fluwx.dart';

import '../config/env.dart';
import 'wechat_auth_client.dart';
import 'wechat_auth_exception.dart';

class _WeChatLifecycleObserver with WidgetsBindingObserver {
  _WeChatLifecycleObserver({required this.onStateChanged});

  final void Function(AppLifecycleState state) onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}

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
    if (defaultTargetPlatform == TargetPlatform.iOS && (universalLink == null || universalLink!.trim().isEmpty)) {
      throw WeChatAuthException(
        '缺少 iOS 微信 Universal Link（WECHAT_UNIVERSAL_LINK），请同时检查 Associated Domains 与 apple-app-site-association',
      );
    }
    final ok = await _fluwx.registerApi(
      appId: appId,
      universalLink: universalLink?.isEmpty ?? true ? null : universalLink,
    );
    if (!ok) {
      throw WeChatAuthException(
        '微信 SDK 注册失败，请检查 WECHAT_APP_ID、WECHAT_UNIVERSAL_LINK、Associated Domains 与 apple-app-site-association',
      );
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
    var sawBackground = false;
    _WeChatLifecycleObserver? observer;
    var cleaned = false;

    void cleanup() {
      if (cleaned) return;
      cleaned = true;
      final o = observer;
      if (o != null) {
        WidgetsBinding.instance.removeObserver(o);
        observer = null;
      }
    }

    FluwxCancelable? cancelable;
    cancelable = _fluwx.addSubscriber((WeChatResponse response) {
      // 某些机型/微信版本在选择账号后取消时，可能先回非 Auth 响应；
      // 只要 errCode=-2 即立即视为用户取消，避免登录按钮长时间 loading。
      final ec = response.errCode;
      if (ec == -2) {
        cancelable?.cancel();
        cleanup();
        if (!completer.isCompleted) completer.completeError(WeChatAuthCanceledException());
        return;
      }

      if (response is! WeChatAuthResponse) return;
      cancelable?.cancel();
      cleanup();
      final auth = response;
      if (auth.isSuccessful && auth.code != null && auth.code!.isNotEmpty) {
        if (!completer.isCompleted) completer.complete(auth.code!);
        return;
      }

      if (!completer.isCompleted) {
        completer.completeError(
          WeChatAuthException(auth.errStr ?? '微信授权失败(${auth.errCode})'),
        );
      }
    });
    final launched = await _fluwx.authBy(which: NormalAuth(scope: 'snsapi_userinfo', state: state));
    if (!launched) {
      cancelable.cancel();
      cleanup();
      throw WeChatAuthException('无法拉起微信授权，请确认已安装微信并检查 iOS Universal Link 配置');
    }

    observer = _WeChatLifecycleObserver(onStateChanged: (s) {
      if (s == AppLifecycleState.inactive || s == AppLifecycleState.paused) {
        sawBackground = true;
        return;
      }
      if (s == AppLifecycleState.resumed && sawBackground && !completer.isCompleted) {
        // 多微信账号选择框取消时可能没有 SDK 回调：回到应用后快速兜底为取消。
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          if (completer.isCompleted) return;
          cancelable?.cancel();
          cleanup();
          completer.completeError(WeChatAuthCanceledException());
        });
      }
    });
    WidgetsBinding.instance.addObserver(observer!);

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        cancelable?.cancel();
        cleanup();
        throw WeChatAuthException('微信授权超时，请重试');
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
