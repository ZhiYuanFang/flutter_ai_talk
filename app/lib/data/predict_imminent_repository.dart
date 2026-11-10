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
      // title=事件名；有父传 parentEventName；永不发 expectLeafTitle
      final body = <String, dynamic>{
        'eventId': id,
        'nextAt': nextAtSec,
        if (p.eventName.trim().isNotEmpty) 'title': p.eventName.trim(),
      };
      final parent = p.parentEventName?.trim() ?? '';
      if (parent.isNotEmpty) body['parentEventName'] = parent;
      if (p.hasExpect) {
        final kind = p.expectKind!.trim();
        body['expectKind'] = kind;
        if (kind == kExpectKindDuration) {
          final sec = p.expectDurationSec;
          if (sec != null && sec > 0) body['expectDurationSec'] = sec;
        } else if (kind == kExpectKindAmount) {
          final amt = p.expectAmount;
          if (amt != null && amt > 0) {
            body['expectAmount'] =
                amt == amt.roundToDouble() ? amt.toInt() : amt;
          }
          final unit = p.expectUnit?.trim() ?? '';
          if (unit.isNotEmpty) body['expectUnit'] = unit;
        }
      }
      events.add(body);
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
