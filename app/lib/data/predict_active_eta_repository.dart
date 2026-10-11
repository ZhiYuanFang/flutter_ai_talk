import '../api/api_client.dart';
import '../api/app_debug_log.dart';
import 'active_timing_eta.dart';

/// 进行中计时 ETA：全量同步到 Go Redis（非 imminent pending）。
class PredictActiveEtaRepository {
  PredictActiveEtaRepository(this._api);

  final ApiClient _api;

  /// PUT 全量替换；[items] 空列表清空服务端。
  Future<void> syncPending({
    required String deviceNo,
    required List<ActiveTimingEtaItem> items,
  }) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;

    final bodyItems = <Map<String, dynamic>>[];
    for (final it in items) {
      if (it.rootEventId < 1 || it.leafEventId < 1) continue;
      final startSec = it.startAt.toUtc().millisecondsSinceEpoch ~/ 1000;
      final endSec = it.expectEndAt.toUtc().millisecondsSinceEpoch ~/ 1000;
      if (startSec < 1 || endSec < 1 || endSec < startSec) continue;
      bodyItems.add(it.toJson());
    }

    await _api.putJsonEnvelope(
      '/device/api/predict/active-eta/pending',
      {
        'deviceNo': dn,
        'items': bodyItems,
      },
    );
    AppDebugLog.predictActiveEta(
      'pending sync ok deviceNoLen=${dn.length} count=${bodyItems.length}',
    );
  }
}
