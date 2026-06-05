import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/api_exceptions.dart';

/// 获取 Apple Sign in with Apple 的 identityToken（JWT）；仅 iOS 原生可用。
Future<String> obtainAppleIdentityToken() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    throw ApiBusinessException(-1, '当前平台不支持 Apple 登录');
  }
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [],
    );
    final token = credential.identityToken?.trim() ?? '';
    if (token.isEmpty) {
      throw ApiBusinessException(-1, 'Apple 未返回 identityToken');
    }
    return token;
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      throw ApiBusinessException(-1, '已取消 Apple 登录');
    }
    throw ApiBusinessException(-1, 'Apple 登录失败（${e.code.name}）');
  } on SignInWithAppleNotSupportedException {
    throw ApiBusinessException(-1, '当前设备不支持 Sign in with Apple');
  }
}
