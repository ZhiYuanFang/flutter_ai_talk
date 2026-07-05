/// `addHistoryEvent` / outbox update POST 结果分类（传输 vs 业务失败）。
enum HistoryPostFailureKind {
  transport,
  business,
  deviceUnbound,
}

class HistoryAddPostOutcome {
  const HistoryAddPostOutcome._({
    this.serverId,
    this.failureKind,
  });

  final String? serverId;
  final HistoryPostFailureKind? failureKind;

  bool get isSuccess => serverId != null;

  bool get isTransportFailure => failureKind == HistoryPostFailureKind.transport;

  bool get isBusinessFailure => failureKind == HistoryPostFailureKind.business;

  factory HistoryAddPostOutcome.success(String serverId) =>
      HistoryAddPostOutcome._(serverId: serverId);

  factory HistoryAddPostOutcome.failure(HistoryPostFailureKind kind) =>
      HistoryAddPostOutcome._(failureKind: kind);
}

class HistoryUpdatePostOutcome {
  const HistoryUpdatePostOutcome._({this.failureKind});

  final HistoryPostFailureKind? failureKind;

  bool get isSuccess => failureKind == null;

  bool get isTransportFailure => failureKind == HistoryPostFailureKind.transport;

  bool get isBusinessFailure => failureKind == HistoryPostFailureKind.business;

  factory HistoryUpdatePostOutcome.success() => const HistoryUpdatePostOutcome._();

  factory HistoryUpdatePostOutcome.failure(HistoryPostFailureKind kind) =>
      HistoryUpdatePostOutcome._(failureKind: kind);
}
