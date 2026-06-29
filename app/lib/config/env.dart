/// 通过 `--dart-define` 注入的运行时配置（勿在仓库中硬编码密钥）。
abstract final class AppEnv {
  /// 联调默认基址；生产通过 `--dart-define=API_BASE_URL=...` 覆盖。
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pangbao.cuplay.top',
  );

  /// 独立 notify 服务基址（维护/公告 banner）；与 [apiBaseUrl] 分离，gateway 维护期间仍可访问。
  /// 优先 `--dart-define=NOTIFY_BASE_URL`；未配置时回退 legacy `STATUS_BASE_URL`。
  static const _notifyBaseUrl = String.fromEnvironment('NOTIFY_BASE_URL', defaultValue: '');
  static const _legacyStatusBaseUrl = String.fromEnvironment(
    'STATUS_BASE_URL',
    defaultValue: 'https://notify.cuplay.top',
  );

  /// notify 服务 HTTP 基址；DNS 默认仍为 status.pangbao.cuplay.top。
  static String get notifyBaseUrl =>
      _notifyBaseUrl.trim().isNotEmpty ? _notifyBaseUrl : _legacyStatusBaseUrl;

  static const userAgreementUrl = String.fromEnvironment(
    'USER_AGREEMENT_URL',
    defaultValue: '$apiBaseUrl/user-agreement.html',
  );

  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '$apiBaseUrl/privacy-policy.html',
  );

  /// 微信开放平台移动应用 AppId（`fluwx.registerApi`）；勿提交 AppSecret。

  /// 微信开放平台移动应用 AppId（`fluwx.registerApi`）；勿提交 AppSecret。
  static const wechatAppId = String.fromEnvironment(
    'WECHAT_APP_ID',
    defaultValue: 'wxe713de83c921f341',
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

  /// 语音转写 WebSocket **完整 URL**；为空时由 [apiBaseUrl] 推导 `/voice/asr/ws`。
  static const wsVoiceAsrUrl = String.fromEnvironment(
    'WS_VOICE_ASR_URL',
    defaultValue: '',
  );

  /// 与网关约定一致：未配置时由 HTTP 基址推导 `ws(s)://host[:port]/voice/asr/ws`。
  static String get wsVoiceAsrUrlEffective {
    if (wsVoiceAsrUrl.isNotEmpty) return wsVoiceAsrUrl;
    final u = Uri.parse(apiBaseUrl);
    if (!u.hasScheme || u.host.isEmpty) return '';
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    var p = u.path;
    if (p == '/') {
      p = '';
    } else if (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    final path = (p.isEmpty ? '/voice/asr/ws' : '$p/voice/asr/ws').replaceAll('//', '/');
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: path.startsWith('/') ? path : '/$path',
    ).toString();
  }

  /// 胖宝诊疗 WebSocket **完整 URL**；为空时由 [wsClinicUrlEffective] 根据 [apiBaseUrl] 推导 `/voice/clinic/ws`。
  static const wsClinicUrl = String.fromEnvironment(
    'WS_CLINIC_URL',
    defaultValue: '',
  );

  /// 与网关约定一致：未配置时由 HTTP 基址推导 `ws(s)://host[:port]/voice/clinic/ws`（MUST NOT 指向 voice-service 内网）。
  static String get wsClinicUrlEffective {
    if (wsClinicUrl.isNotEmpty) return wsClinicUrl;
    final u = Uri.parse(apiBaseUrl);
    if (!u.hasScheme || u.host.isEmpty) return '';
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    var p = u.path;
    if (p == '/') {
      p = '';
    } else if (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    final path = (p.isEmpty ? '/voice/clinic/ws' : '$p/voice/clinic/ws').replaceAll('//', '/');
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: path.startsWith('/') ? path : '/$path',
    ).toString();
  }

  /// UCG 聊天 WebSocket **完整 URL**；为空时由 [wsUcgChatUrlEffective] 根据 [apiBaseUrl] 推导为 `/ucg/app/ws/chat`。
  static const wsUcgChatUrl = String.fromEnvironment(
    'WS_UCG_CHAT_URL',
    defaultValue: '',
  );

  /// 与网关约定一致：未配置 `WS_UCG_CHAT_URL` 时由 HTTP 基址推导 `ws(s)://host[:port]/ucg/app/ws/chat`（含 [apiBaseUrl] 的 path 前缀）。
  static String get wsUcgChatUrlEffective {
    if (wsUcgChatUrl.isNotEmpty) return wsUcgChatUrl;
    final u = Uri.parse(apiBaseUrl);
    if (!u.hasScheme || u.host.isEmpty) return '';
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    var p = u.path;
    if (p == '/') {
      p = '';
    } else if (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    final path = (p.isEmpty ? '/ucg/app/ws/chat' : '$p/ucg/app/ws/chat').replaceAll('//', '/');
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: path.startsWith('/') ? path : '/$path',
    ).toString();
  }

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
    defaultValue: '6774418472',
  );

  /// 为 `true` 时跳过版本接口、强制出现「发现新版本」（仅联调 UI）。
  static const mockNewerVersion = bool.fromEnvironment(
    'MOCK_NEWER_VERSION',
    defaultValue: false,
  );

  /// 为 `true` 时原生端 HTTP/WebSocket 仅使用 IPv4（`HttpOverrides`）；默认双栈。
  static const forceIpv4 = bool.fromEnvironment(
    'FORCE_IPV4',
    defaultValue: false,
  );
}
