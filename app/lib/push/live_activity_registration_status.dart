/// 系统 Live Activities 允许态（原生探测）。
enum LiveActivitySystemAuth {
  /// 系统允许。
  enabled,

  /// 系统关闭或未允许。
  disabled,

  /// 非 iOS / 过低版本等。
  unsupported,
}

/// 锁屏开通/重试失败类别（短码，便于客服复述）。
enum LiveActivityErrorCategory {
  /// 无错误。
  none,

  /// 系统版本不支持 Push-to-Start。
  osUnsupported,

  /// 系统未允许 Live Activities。
  systemDisallowed,

  /// 超时内未收到任何系统 PTS 事件。
  noSystemToken,

  /// 已见 token 但 live-activity/register HTTP/业务失败。
  registerHttpFailed,

  /// 原生已 invoke 到 Dart 通道，但本轮未见 PTS 事件。
  nativeDeliverDartMiss,

  /// 此前已成功，本轮超时未收到新事件。
  timeoutKeptPriorSuccess,

  /// 其它/未知。
  unknown,
}

/// 锁屏 Live Activity 注册显态（不含 token 明文；统一单轨）。
class LiveActivityRegistrationStatus {
  const LiveActivityRegistrationStatus({
    required this.listening,
    required this.pushToStartSupported,
    required this.systemAuth,
    required this.pushToStartOk,
    this.ptsEventSeen = false,
    this.lastSuccessAt,
    this.pushToStartDeliverCount = 0,
    this.iosVersionLabel = '',
    this.lastError,
    this.errorCategory = LiveActivityErrorCategory.none,
    this.retrying = false,
  });

  factory LiveActivityRegistrationStatus.initial() =>
      const LiveActivityRegistrationStatus(
        listening: false,
        pushToStartSupported: false,
        systemAuth: LiveActivitySystemAuth.unsupported,
        pushToStartOk: false,
      );

  final bool listening;
  final bool pushToStartSupported;
  final LiveActivitySystemAuth systemAuth;
  /// 统一轨 Push-to-Start register 曾成功。
  final bool pushToStartOk;
  /// 本进程是否见过 push_to_start 事件（不论 HTTP）。
  final bool ptsEventSeen;
  final DateTime? lastSuccessAt;
  final int pushToStartDeliverCount;
  final String iosVersionLabel;
  final String? lastError;
  final LiveActivityErrorCategory errorCategory;
  final bool retrying;

  /// 已开通：系统支持且允许，且统一轨 Push-to-Start 已成功上报。
  bool get isFullyEnabled =>
      pushToStartSupported &&
      systemAuth == LiveActivitySystemAuth.enabled &&
      pushToStartOk;

  String get errorCategoryCode {
    switch (errorCategory) {
      case LiveActivityErrorCategory.none:
        return 'none';
      case LiveActivityErrorCategory.osUnsupported:
        return 'os_unsupported';
      case LiveActivityErrorCategory.systemDisallowed:
        return 'system_disallowed';
      case LiveActivityErrorCategory.noSystemToken:
        return 'no_system_token';
      case LiveActivityErrorCategory.registerHttpFailed:
        return 'register_http_failed';
      case LiveActivityErrorCategory.nativeDeliverDartMiss:
        return 'native_deliver_dart_miss';
      case LiveActivityErrorCategory.timeoutKeptPriorSuccess:
        return 'timeout_kept_prior_success';
      case LiveActivityErrorCategory.unknown:
        return 'unknown';
    }
  }

  /// 可复制诊断一行（无 token）。
  String get diagnosticSummary {
    final ios = iosVersionLabel.isEmpty ? '?' : iosVersionLabel;
    return 'ios=$ios listening=${listening ? 1 : 0} '
        'ptsDeliver=$pushToStartDeliverCount '
        'ptsSeen=${ptsEventSeen ? 1 : 0} '
        'ptsOk=${pushToStartOk ? 1 : 0} '
        'err=$errorCategoryCode';
  }

  LiveActivityRegistrationStatus copyWith({
    bool? listening,
    bool? pushToStartSupported,
    LiveActivitySystemAuth? systemAuth,
    bool? pushToStartOk,
    bool? ptsEventSeen,
    DateTime? lastSuccessAt,
    int? pushToStartDeliverCount,
    String? iosVersionLabel,
    String? lastError,
    bool clearLastError = false,
    LiveActivityErrorCategory? errorCategory,
    bool clearErrorCategory = false,
    bool? retrying,
  }) {
    return LiveActivityRegistrationStatus(
      listening: listening ?? this.listening,
      pushToStartSupported: pushToStartSupported ?? this.pushToStartSupported,
      systemAuth: systemAuth ?? this.systemAuth,
      pushToStartOk: pushToStartOk ?? this.pushToStartOk,
      ptsEventSeen: ptsEventSeen ?? this.ptsEventSeen,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      pushToStartDeliverCount:
          pushToStartDeliverCount ?? this.pushToStartDeliverCount,
      iosVersionLabel: iosVersionLabel ?? this.iosVersionLabel,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      errorCategory: clearErrorCategory
          ? LiveActivityErrorCategory.none
          : (errorCategory ?? this.errorCategory),
      retrying: retrying ?? this.retrying,
    );
  }
}

/// 错误类别对应人话短句。
String liveActivityErrorCategoryMessage(LiveActivityErrorCategory c) {
  switch (c) {
    case LiveActivityErrorCategory.none:
      return '';
    case LiveActivityErrorCategory.osUnsupported:
      return '系统版本过低，需要 iOS 17.2 及以上才能开通锁屏推送';
    case LiveActivityErrorCategory.systemDisallowed:
      return '系统未允许实时活动 / Live Activities，请在系统设置中开启后再重试';
    case LiveActivityErrorCategory.noSystemToken:
      return '未收到系统 Push-to-Start token（系统未下发或本机未接到）';
    case LiveActivityErrorCategory.registerHttpFailed:
      return '已收到系统 token，但上报 live-activity/register 失败';
    case LiveActivityErrorCategory.nativeDeliverDartMiss:
      return '原生已投递 token，但应用未收到（通道异常）';
    case LiveActivityErrorCategory.timeoutKeptPriorSuccess:
      return '本次重试未收到新的系统 token；仍保留上次开通成功记录';
    case LiveActivityErrorCategory.unknown:
      return '开通失败（原因未知）';
  }
}
