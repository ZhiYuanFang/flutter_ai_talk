/// 系统 Live Activities 允许态（原生探测）。
enum LiveActivitySystemAuth {
  /// 系统允许。
  enabled,

  /// 系统关闭或未允许。
  disabled,

  /// 非 iOS / 过低版本等。
  unsupported,
}

/// 锁屏 Live Activity 注册显态（不含 token 明文）。
class LiveActivityRegistrationStatus {
  const LiveActivityRegistrationStatus({
    required this.listening,
    required this.pushToStartSupported,
    required this.systemAuth,
    required this.imminentPushToStartOk,
    required this.timingPushToStartOk,
    this.imminentLastSuccessAt,
    this.timingLastSuccessAt,
    this.lastError,
    this.retrying = false,
  });

  /// 初始未知态（加载中）。
  factory LiveActivityRegistrationStatus.initial() =>
      const LiveActivityRegistrationStatus(
        listening: false,
        pushToStartSupported: false,
        systemAuth: LiveActivitySystemAuth.unsupported,
        imminentPushToStartOk: false,
        timingPushToStartOk: false,
      );

  final bool listening;
  final bool pushToStartSupported;
  final LiveActivitySystemAuth systemAuth;
  final bool imminentPushToStartOk;
  final bool timingPushToStartOk;
  final DateTime? imminentLastSuccessAt;
  final DateTime? timingLastSuccessAt;
  final String? lastError;
  final bool retrying;

  /// 已开通：系统支持且允许，且两类 Push-to-Start 均成功上报过。
  bool get isFullyEnabled =>
      pushToStartSupported &&
      systemAuth == LiveActivitySystemAuth.enabled &&
      imminentPushToStartOk &&
      timingPushToStartOk;

  LiveActivityRegistrationStatus copyWith({
    bool? listening,
    bool? pushToStartSupported,
    LiveActivitySystemAuth? systemAuth,
    bool? imminentPushToStartOk,
    bool? timingPushToStartOk,
    DateTime? imminentLastSuccessAt,
    DateTime? timingLastSuccessAt,
    String? lastError,
    bool clearLastError = false,
    bool? retrying,
  }) {
    return LiveActivityRegistrationStatus(
      listening: listening ?? this.listening,
      pushToStartSupported: pushToStartSupported ?? this.pushToStartSupported,
      systemAuth: systemAuth ?? this.systemAuth,
      imminentPushToStartOk:
          imminentPushToStartOk ?? this.imminentPushToStartOk,
      timingPushToStartOk: timingPushToStartOk ?? this.timingPushToStartOk,
      imminentLastSuccessAt:
          imminentLastSuccessAt ?? this.imminentLastSuccessAt,
      timingLastSuccessAt: timingLastSuccessAt ?? this.timingLastSuccessAt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      retrying: retrying ?? this.retrying,
    );
  }
}
