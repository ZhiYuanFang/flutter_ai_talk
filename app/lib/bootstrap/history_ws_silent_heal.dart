import 'dart:async';

import '../api/app_debug_log.dart';
import '../data/feed_repository.dart';
import 'gateway_bootstrap_gate.dart';

/// 主壳历史 WS 静默自愈：预算（默认 2）+ single-flight。
///
/// 登出 / `releasePangbaoHomeTransports` 须 [reset]；`ready` 成功须 [onReady]。
class HistoryWsSilentHeal {
  HistoryWsSilentHeal._();

  /// 主壳会话内对 gaveUp / 未 ready 的 resetStrike+reconnect 上限。
  static const budgetMax = 2;

  /// 激活后等待 ready / gaveUp / 超时再决定是否自愈。
  static const readyWatchTimeout = Duration(seconds: 25);

  static var _used = 0;
  static Future<void>? _inFlight;

  static int get used => _used;

  static bool get hasBudget => _used < budgetMax;

  /// 登出或离开主壳：清预算与 in-flight 标记。
  static void reset() {
    _used = 0;
    _inFlight = null;
  }

  /// 历史 WS 已 ready：清零预算。
  static void onReady() {
    _used = 0;
  }

  /// 若未 ready 且预算未尽：resetStrike + reconnect，计入一次预算。
  static Future<void> tryHeal({
    required FeedRepository feed,
    required bool isLoggedIn,
    required bool shellMounted,
    required String reason,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final flight = _tryHealOnce(
      feed: feed,
      isLoggedIn: isLoggedIn,
      shellMounted: shellMounted,
      reason: reason,
    );
    _inFlight = flight;
    return flight.whenComplete(() {
      if (identical(_inFlight, flight)) _inFlight = null;
    });
  }

  static Future<void> _tryHealOnce({
    required FeedRepository feed,
    required bool isLoggedIn,
    required bool shellMounted,
    required String reason,
  }) async {
    if (!shellMounted) return;
    if (!GatewayBootstrapGate.isLoggedInComplete) return;
    if (!isLoggedIn) return;

    if (feed.isHistoryWebSocketReady) {
      onReady();
      return;
    }

    if (!hasBudget) {
      AppDebugLog.wsTransport(
        'history silentHeal skip reason=$reason '
        'budgetExhausted used=$_used/$budgetMax phase=${feed.historyWsPhase.name}',
      );
      return;
    }

    _used++;
    final phase = feed.historyWsPhase;
    AppDebugLog.wsTransport(
      'history silentHeal reason=$reason '
      'budget=$_used/$budgetMax phase=${phase.name}',
    );
    await feed.reconnectHistoryWebSocket(resetStrike: true);
    if (feed.isHistoryWebSocketReady) {
      onReady();
    }
  }
}
