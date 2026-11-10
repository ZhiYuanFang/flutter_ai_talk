import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/history_latest_by_event.dart';
import '../data/smart_prediction_rows.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

final historyLatestByEventRepositoryProvider =
    Provider<HistoryLatestByEventRepository>((ref) {
  return HistoryLatestByEventRepository(
    ref.watch(authorizedApiClientProvider),
  );
});

/// eventId → 展示用上一次（含确认空）。
final historyLatestByEventCacheProvider = NotifierProvider<
    HistoryLatestByEventCacheNotifier, Map<String, PredictionLastOccurrenceRef>>(
  HistoryLatestByEventCacheNotifier.new,
);

class HistoryLatestByEventCacheNotifier
    extends Notifier<Map<String, PredictionLastOccurrenceRef>> {
  @override
  Map<String, PredictionLastOccurrenceRef> build() => const {};

  void replaceAll(Map<String, PredictionLastOccurrenceRef> next) {
    state = Map<String, PredictionLastOccurrenceRef>.unmodifiable(next);
  }

  void clear() {
    state = const {};
  }
}

Future<void>? _historyLatestSyncInFlight;
var _historyLatestFailCount = 0;
DateTime? _historyLatestCooldownUntil;
String? _lastHistoryLatestFingerprint;

const _kHistoryLatestFailThreshold = 3;
const _kHistoryLatestCooldown = Duration(seconds: 60);

/// 显式刷新批量最近发生（预测页 / 历史变更后）；single-flight + 失败熔断。
Future<void> requestHistoryLatestByEventSync(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();
  return Future<void>(() => _requestHistoryLatestByEventSyncNow(ref));
}

Future<void> _requestHistoryLatestByEventSyncNow(dynamic ref) async {
  if (_historyLatestSyncInFlight != null) {
    await _historyLatestSyncInFlight;
    return;
  }
  final run = _syncHistoryLatestByEventOnce(ref);
  _historyLatestSyncInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_historyLatestSyncInFlight, run)) {
      _historyLatestSyncInFlight = null;
    }
  }
}

Future<void> _syncHistoryLatestByEventOnce(dynamic ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final cooldown = _historyLatestCooldownUntil;
  if (cooldown != null && DateTime.now().isBefore(cooldown)) {
    return;
  }

  try {
    final dn = (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
            .asData
            ?.value
            ?.trim() ??
        '';
    if (dn.isEmpty) return;

    final map = await (ref.read(historyLatestByEventRepositoryProvider)
            as HistoryLatestByEventRepository)
        .fetchLatestByEvent(deviceNo: dn);
    if (map == null) {
      _historyLatestFailCount++;
      AppDebugLog.historyLatest(
        'sync failCount=$_historyLatestFailCount (null)',
      );
      if (_historyLatestFailCount >= _kHistoryLatestFailThreshold) {
        _historyLatestCooldownUntil =
            DateTime.now().add(_kHistoryLatestCooldown);
      }
      return;
    }

    final next = <String, PredictionLastOccurrenceRef>{
      for (final e in map.entries) e.key: e.value.toLastRef(),
    };
    final fp = next.isEmpty
        ? 'empty'
        : next.entries
            .map((e) =>
                '${e.key}:${e.value.at?.toUtc().millisecondsSinceEpoch ?? 0}')
            .join('|');
    if (fp == _lastHistoryLatestFingerprint) {
      _historyLatestFailCount = 0;
      _historyLatestCooldownUntil = null;
      return;
    }

    (ref.read(historyLatestByEventCacheProvider.notifier)
            as HistoryLatestByEventCacheNotifier)
        .replaceAll(next);
    _lastHistoryLatestFingerprint = fp;
    _historyLatestFailCount = 0;
    _historyLatestCooldownUntil = null;
  } catch (e) {
    _historyLatestFailCount++;
    AppDebugLog.historyLatest(
      'sync err=$e failCount=$_historyLatestFailCount',
    );
    if (_historyLatestFailCount >= _kHistoryLatestFailThreshold) {
      _historyLatestCooldownUntil =
          DateTime.now().add(_kHistoryLatestCooldown);
      AppDebugLog.historyLatest(
        'sync cooldown ${_kHistoryLatestCooldown.inSeconds}s',
      );
    }
  }
}

/// 预测页挂载时预取（不在 provider create 自动发 HTTP）。
final historyLatestByEventPrefetchProvider =
    FutureProvider.autoDispose<void>((ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  await requestHistoryLatestByEventSync(ref);
});
