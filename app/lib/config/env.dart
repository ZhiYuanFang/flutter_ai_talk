/// 通过 `--dart-define` 注入的运行时配置（勿在仓库中硬编码密钥）。
abstract final class AppEnv {
  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://example.com/privacy',
  );

  /// 联调默认基址；生产通过 `--dart-define=API_BASE_URL=...` 覆盖。
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://www.cuplay.top:9702',
  );

  /// 微信开放平台移动应用 AppId（`fluwx.registerApi`）；勿提交 AppSecret。
  static const wechatAppId = String.fromEnvironment(
    'WECHAT_APP_ID',
    defaultValue: '',
  );

  /// iOS Universal Links 前缀（须与开放平台及 `apple-app-site-association` 一致）。
  static const wechatUniversalLink = String.fromEnvironment(
    'WECHAT_UNIVERSAL_LINK',
    defaultValue: '',
  );

  /// 网站应用 AppId；留空则网页授权使用 [wechatAppId]。
  static const wechatWebAppId = String.fromEnvironment(
    'WECHAT_WEB_APP_ID',
    defaultValue: '',
  );

  /// 网页授权回调完整 URL（须在微信开放平台登记，如 `https://your.domain/auth/wechat/callback`）。
  static const wechatOAuthRedirectUri = String.fromEnvironment(
    'WECHAT_OAUTH_REDIRECT_URI',
    defaultValue: '',
  );

  /// 网页授权使用的 AppId：`WECHAT_WEB_APP_ID` 非空则用之，否则 [wechatAppId]。
  static String get wechatWebAppIdEffective =>
      wechatWebAppId.isNotEmpty ? wechatWebAppId : wechatAppId;

  /// 微信登录联调用临时 code（请求体字段名为 `jsCode`）；无 SDK 时回退。
  static const wxLoginCode = String.fromEnvironment(
    'WX_LOGIN_CODE',
    defaultValue: '',
  );

  /// 历史 WebSocket **完整 URL**；为空时由 [wsHistoryUrlEffective] 根据 [apiBaseUrl] 推导为 `/device/app/ws/history`。
  static const wsHistoryUrl = String.fromEnvironment(
    'WS_HISTORY_URL',
    defaultValue: '',
  );

  /// 与网关约定一致：未配置 `WS_HISTORY_URL` 时由 HTTP 基址推导 `ws(s)://host[:port]/device/app/ws/history`（含 [apiBaseUrl] 的 path 前缀）。
  static String get wsHistoryUrlEffective {
    if (wsHistoryUrl.isNotEmpty) return wsHistoryUrl;
    final u = Uri.parse(apiBaseUrl);
    if (!u.hasScheme || u.host.isEmpty) return '';
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    var p = u.path;
    if (p == '/') {
      p = '';
    } else if (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    final path = (p.isEmpty ? '/device/app/ws/history' : '$p/device/app/ws/history').replaceAll('//', '/');
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: path.startsWith('/') ? path : '/$path',
    ).toString();
  }

  /// 刷新 access token 的 POST path（相对 [apiBaseUrl]）；请求体字段 `refreshToken`；空字符串则不做静默刷新。
  static const refreshTokenPath = String.fromEnvironment(
    'REFRESH_TOKEN_PATH',
    defaultValue: '/device/app/api/token/refresh',
  );

  /// iOS App Store 数字 ID（占位）；真上架后替换。
  static const iosAppStoreId = String.fromEnvironment(
    'IOS_APP_STORE_ID',
    defaultValue: '0000000000',
  );

  /// 为 `true` 时跳过版本接口、强制出现「发现新版本」（仅联调 UI）。
  static const mockNewerVersion = bool.fromEnvironment(
    'MOCK_NEWER_VERSION',
    defaultValue: false,
  );
}
