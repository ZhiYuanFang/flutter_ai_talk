import '../api/api_client.dart';
import '../api/app_debug_log.dart';
import 'event_next_predictor.dart';

/// 预测临近离线提醒：全量同步 pending 到 Go。
class PredictImminentRepository {
  PredictImminentRepository(this._api);

  final ApiClient _api;

  /// PUT 全量替换；[events] 空列表清空服务端闹钟。
  Future<void> syncPending({
    required String deviceNo,
    required List<EventNextPrediction> predictions,
  }) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;

    final events = <Map<String, dynamic>>[];
    for (final p in predictions) {
      final id = int.tryParse(p.eventId.trim());
      if (id == null || id < 1) {
        AppDebugLog.predictImminent(
          'skip non-int eventId=${p.eventId}',
        );
        continue;
      }
      final nextAtSec = p.nextAt.toUtc().millisecondsSinceEpoch ~/ 1000;
      if (nextAtSec < 1) continue;
      events.add({
        'eventId': id,
        'nextAt': nextAtSec,
        if (p.eventName.trim().isNotEmpty) 'title': p.eventName.trim(),
      });
    }

    await _api.putJsonEnvelope(
      '/device/api/predict/imminent/pending',
      {
        'deviceNo': dn,
        'events': events,
      },
    );
    AppDebugLog.predictImminent(
      'pending sync ok deviceNoLen=${dn.length} count=${events.length}',
    );
  }
}
