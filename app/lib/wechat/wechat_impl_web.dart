import 'dart:html' as html;

import '../config/env.dart';
import 'wechat_auth_client.dart';
import 'wechat_auth_exception.dart';

const _kState = 'pangbao_wx_oauth_state';
const _kCode = 'pangbao_wx_oauth_code';

/// Web：仅从 sessionStorage 读取回调页写入的 `code`（不发起 OAuth 跳转）。
class WebWeChatCodeReaderClient implements WeChatAuthClient {
  @override
  Future<String> obtainWxCode() async {
    final code = html.window.sessionStorage[_kCode];
    final err = html.window.sessionStorage['pangbao_wx_oauth_error'];
    html.window.sessionStorage.remove(_kCode);
    html.window.sessionStorage.remove('pangbao_wx_oauth_error');
    if (err != null && err.isNotEmpty) {
      if (err == 'access_denied') {
        throw WeChatAuthCanceledException('用户拒绝授权');
      }
      throw WeChatAuthException(err);
    }
    if (code == null || code.isEmpty) {
      throw WeChatAuthException('未找到微信授权码，请先完成网页授权');
    }
    return code;
  }
}

/// 跳转微信网页授权（整页离开当前 Flutter）。
void redirectToWeChatWebAuthorize() {
  final appId = AppEnv.wechatWebAppIdEffective;
  final redirect = AppEnv.wechatOAuthRedirectUri;
  if (appId.isEmpty || redirect.isEmpty) {
    throw StateError('缺少 WECHAT_WEB_APP_ID 或 WECHAT_OAUTH_REDIRECT_URI');
  }
  final state = '${DateTime.now().millisecondsSinceEpoch}_${html.window.sessionStorage.length}';
  html.window.sessionStorage[_kState] = state;
  final redir = Uri.encodeComponent(redirect);
  final url =
      'https://open.weixin.qq.com/connect/oauth2/authorize?appid=$appId&redirect_uri=$redir&response_type=code&scope=snsapi_userinfo&state=$state#wechat_redirect';
  html.window.location.assign(url);
}

/// 在 OAuth 回调页解析 query，写入 sessionStorage 后交给路由。
void handleWeChatOAuthCallbackQuery(Uri uri) {
  final err = uri.queryParameters['error'];
  if (err != null && err.isNotEmpty) {
    html.window.sessionStorage['pangbao_wx_oauth_error'] = err;
    html.window.sessionStorage.remove(_kCode);
    return;
  }
  final code = uri.queryParameters['code'];
  final state = uri.queryParameters['state'];
  final saved = html.window.sessionStorage[_kState];
  if (code == null || code.isEmpty) {
    html.window.sessionStorage['pangbao_wx_oauth_error'] = 'missing_code';
    return;
  }
  if (state == null || state.isEmpty || state != saved) {
    html.window.sessionStorage['pangbao_wx_oauth_error'] = 'state_mismatch';
    html.window.sessionStorage.remove(_kCode);
    return;
  }
  html.window.sessionStorage[_kCode] = code;
  html.window.sessionStorage.remove(_kState);
  html.window.sessionStorage.remove('pangbao_wx_oauth_error');
}

/// 读取并清除 OAuth 错误标记（供回调页 Toast）。
String? consumeWeChatOAuthCallbackError() {
  final e = html.window.sessionStorage['pangbao_wx_oauth_error'];
  if (e != null && e.isNotEmpty) {
    html.window.sessionStorage.remove('pangbao_wx_oauth_error');
    return e;
  }
  return null;
}

WeChatAuthClient? createWeChatAuthClient() {
  if (AppEnv.wechatWebAppIdEffective.isEmpty || AppEnv.wechatOAuthRedirectUri.isEmpty) return null;
  return WebWeChatCodeReaderClient();
}

/// 是否存在待消费的网页授权码（用于登录页自动完成登录）。
bool hasPendingWeChatWebCode() {
  final c = html.window.sessionStorage[_kCode];
  return c != null && c.isNotEmpty;
}

/// 清除网页 OAuth 残留（code/state/error），不发起登录。
void clearPendingWeChatWebOAuthStorage() {
  html.window.sessionStorage.remove(_kCode);
  html.window.sessionStorage.remove(_kState);
  html.window.sessionStorage.remove('pangbao_wx_oauth_error');
}
