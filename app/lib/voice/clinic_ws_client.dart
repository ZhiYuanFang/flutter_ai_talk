import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ai_quota_codes.dart';
import '../config/env.dart';
import '../data/feed_repository.dart';
import '../network/resilient_websocket_client.dart';
import '../network/ws_auth_error_handler.dart';
import '../network/ws_connect_context.dart';
import '../network/ws_connection_config.dart';
import '../network/ws_phase_mapping.dart';

/// 胖宝陪伴/诊疗 WebSocket 客户端：连接后首帧 auth，auth_ok 后接收 session_sync 并可发送 question/cancel。
///
/// 业务说明：接受 [Ref] 以便壳级 Provider 持有；建连走 [prepareDeviceWsConnectContext]。
class ClinicWsClient {
  ClinicWsClient({
    required this.wsUrl,
    required Ref ref,
    required this.deviceNoGetter,
  }) : _ref = ref {
    _wsClient = ResilientWebSocketClient(
      WsConnectionConfig(
        url: wsUrl.trim(),
        channelLabel: 'clinic',
        requireHandshakePong: false,
        shouldConnect: () async {
          final url = wsUrl.trim();
          if (url.isEmpty) return false;
          final dn = deviceNoGetter()?.trim();
          return dn != null && dn.isNotEmpty;
        },
        prepareToken: () => prepareDeviceWsConnectContext(
          _ref,
          deviceNo: deviceNoGetter()?.trim(),
          toastOnHardFailure: false,
          toastOnDeviceSyncFailure: false,
        ),
        buildAuthFrame: (ctx) => {
          'type': 'auth',
          'accessToken': ctx.accessToken,
          'deviceNo': ctx.deviceNo,
        },
        onApplicationFrame: _onApplicationFrame,
        onErrorFrame: _onClinicWsError,
      ),
    );
    _wsReadySub = _wsClient.readyStream.listen(_emitWsReady);
    _wsPhaseSub = _wsClient.phaseStream.listen((p) => _emitPhase(historyWsPhaseFromShared(p)));
  }

  final String wsUrl;
  final Ref _ref;
  final String? Function() deviceNoGetter;

  late final ResilientWebSocketClient _wsClient;
  String? _activeTurnId;
  StreamSubscription<bool>? _wsReadySub;
  StreamSubscription<dynamic>? _wsPhaseSub;
  HistoryWsPhase _phase = HistoryWsPhase.disconnected;
  var _wsReady = false;

  final _frameController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _wsReadyController = StreamController<bool>.broadcast();
  final StreamController<HistoryWsPhase> _phaseController =
      StreamController<HistoryWsPhase>.broadcast();

  Stream<Map<String, dynamic>> get frames => _frameController.stream;

  bool get isConnected => _wsClient.isReady;

  bool get isClinicWebSocketReady =>
      wsUrl.trim().isNotEmpty &&
      (deviceNoGetter()?.isNotEmpty ?? false) &&
      _wsReady;

  Stream<bool> get clinicWsReadyStream => _wsReadyController.stream;

  HistoryWsPhase get clinicWsPhase => _phase;

  Stream<HistoryWsPhase> get clinicWsPhaseStream => _phaseController.stream;

  void _emitWsReady(bool v) {
    if (_wsReady == v) return;
    _wsReady = v;
    if (!_wsReadyController.isClosed) {
      _wsReadyController.add(v);
    }
  }

  void _emitPhase(HistoryWsPhase next) {
    if (_phase == next) return;
    _phase = next;
    if (!_phaseController.isClosed) {
      _phaseController.add(next);
    }
  }

  /// 当前进行中的 turnId（question 发送后至 answer_done / turn_cancelled 前）。
  String? get activeTurnId => _activeTurnId;

  void dispose() {
    unawaited(cancelActiveAndDisconnect());
    unawaited(_wsReadySub?.cancel());
    unawaited(_wsPhaseSub?.cancel());
    _wsClient.dispose();
    unawaited(_wsReadyController.close());
    unawaited(_phaseController.close());
    unawaited(_frameController.close());
  }

  void setConnectionDesired(bool desired) {
    if (desired) {
      _wsClient.setConnectionDesired(true);
    } else {
      unawaited(cancelActiveAndDisconnect());
    }
  }

  Future<void> reconnect({bool resetStrike = false}) async {
    _wsClient.setConnectionDesired(true);
    await _wsClient.reconnect(resetStrike: resetStrike);
  }

  void onAppLifecycleResumed() => _wsClient.onAppLifecycleResumed();

  /// 发送 question 并分配新 turnId；返回 turnId 供 UI 过滤 stale 帧。
  Future<String?> sendQuestion(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (!await _ensureReady()) return null;
    final turnId = _newTurnId();
    _activeTurnId = turnId;
    _wsClient.sendJson({'type': 'question', 'text': trimmed, 'turnId': turnId});
    return turnId;
  }

  /// 显式 cancel 指定 turn；离开页面/后台时 best-effort 发送后再断连。
  Future<void> sendCancel(String turnId) async {
    final tid = turnId.trim();
    if (tid.isEmpty || !_wsClient.isReady) return;
    _wsClient.sendJson({'type': 'cancel', 'turnId': tid});
  }

  /// 先 cancel active turn（若有），再断开 WebSocket。
  Future<void> cancelActiveAndDisconnect() async {
    final turnId = _activeTurnId;
    if (turnId != null && turnId.isNotEmpty && _wsClient.isReady) {
      _wsClient.sendJson({'type': 'cancel', 'turnId': turnId});
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    _activeTurnId = null;
    _wsClient.setConnectionDesired(false);
  }

  Future<bool> _ensureReady({Duration timeout = const Duration(seconds: 15)}) async {
    if (_wsClient.isReady) return true;
    _wsClient.setConnectionDesired(true);
    try {
      await _wsClient.readyStream.firstWhere((r) => r).timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _clearActiveTurn(String turnId) {
    if (_activeTurnId == turnId) {
      _activeTurnId = null;
    }
  }

  void _onApplicationFrame(Map<String, dynamic> decoded) {
    final type = (decoded['type'] as String? ?? '').toLowerCase();
    if (type == 'answer_done') {
      _clearActiveTurn(decoded['turnId'] as String? ?? '');
    } else if (type == 'turn_cancelled') {
      _clearActiveTurn(decoded['turnId'] as String? ?? '');
    }
    if (!_frameController.isClosed) {
      _frameController.add(decoded);
    }
  }

  Future<bool> _onClinicWsError(Map<String, dynamic> decoded) async {
    // 鉴权/额度统一走 Ref 版 handler（壳级 Provider 与 Widget 共用）
    final result = await handleWsAuthOrQuotaError(_ref, decoded);
    if (result.forwardToUi && !_frameController.isClosed) {
      _frameController.add(decoded);
    }
    return result.scheduleReconnect;
  }

  /// 解析 WS error 帧是否为额度/登录业务码。
  static int? businessCodeFromFrame(Map<String, dynamic> frame) {
    return parseWsErrorBusinessCode(frame);
  }

  /// 解析 session_sync 帧中的已完成 Q&A 轮次（不含 thinking）。
  static List<ClinicSessionTurn> parseSessionSyncTurns(Map<String, dynamic> frame) {
    final raw = frame['turns'];
    if (raw is! List) return const [];
    final out = <ClinicSessionTurn>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final q = (item['question'] as String? ?? '').trim();
      final a = (item['answer'] as String? ?? '').trim();
      if (q.isEmpty || a.isEmpty) continue;
      out.add(ClinicSessionTurn(question: q, answer: a));
    }
    return out;
  }

  static String _newTurnId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }
}

/// session_sync 中单轮已完成 Q&A（服务端 Redis 不存 thinking）。
class ClinicSessionTurn {
  const ClinicSessionTurn({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// 默认由 gateway-app 主机推导的胖宝 WS URL。
String defaultClinicWsUrl() => AppEnv.wsClinicUrlEffective;
