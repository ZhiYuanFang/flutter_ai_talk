import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/event_next_predictor.dart';
import '../data/predict_imminent_repository.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';
import 'smart_prediction_provider.dart';

final predictImminentRepositoryProvider =
    Provider<PredictImminentRepository>((ref) {
  return PredictImminentRepository(ref.watch(authorizedApiClientProvider));
});

Future<void>? _predictImminentSyncInFlight;
var _predictImminentFailCount = 0;
DateTime? _predictImminentCooldownUntil;
String? _lastPredictImminentFingerprint;

const _kPredictImminentFailThreshold = 3;
const _kPredictImminentCooldown = Duration(seconds: 60);

/// 主壳须 [ref.watch] 本 provider 以激活 listen；与推送 register 解耦。
final predictImminentPendingSyncProvider = Provider<void>((ref) {
  ref.listen<List<EventNextPrediction>>(smartPredictionsProvider, (_, next) {
    unawaited(_syncPredictImminentPending(ref, next));
  });
  ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
    final dn = next.asData?.value?.trim();
    if (dn == null || dn.isEmpty) return;
    unawaited(
      _syncPredictImminentPending(ref, ref.read(smartPredictionsProvider)),
    );
  });
  ref.listen(sessionProvider, (prev, next) {
    if (!next.isLoggedIn) {
      _lastPredictImminentFingerprint = null;
      _predictImminentFailCount = 0;
      _predictImminentCooldownUntil = null;
      return;
    }
    unawaited(
      _syncPredictImminentPending(ref, ref.read(smartPredictionsProvider)),
    );
  });

  // 首次订阅时同步一次当前预测
  unawaited(
    _syncPredictImminentPending(ref, ref.read(smartPredictionsProvider)),
  );
});

Future<void> _syncPredictImminentPending(
  Ref ref,
  List<EventNextPrediction> predictions,
) async {
  if (_predictImminentSyncInFlight != null) {
    await _predictImminentSyncInFlight;
    return;
  }
  final run = _syncPredictImminentPendingOnce(ref, predictions);
  _predictImminentSyncInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_predictImminentSyncInFlight, run)) {
      _predictImminentSyncInFlight = null;
    }
  }
}

Future<void> _syncPredictImminentPendingOnce(
  Ref ref,
  List<EventNextPrediction> predictions,
) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final cooldown = _predictImminentCooldownUntil;
  if (cooldown != null && DateTime.now().isBefore(cooldown)) {
    return;
  }
  final dn = ref.read(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  if (dn.isEmpty) return;

  // 指纹：避免预测 clock 无关重建刷 HTTP；空列表也上报以清空。
  final fp = predictions.isEmpty
      ? 'empty'
      : predictions
          .map((p) =>
              '${p.eventId}:${p.nextAt.toUtc().millisecondsSinceEpoch ~/ 1000}')
          .join('|');
  if (fp == _lastPredictImminentFingerprint) return;

  try {
    await ref.read(predictImminentRepositoryProvider).syncPending(
          deviceNo: dn,
          predictions: predictions,
        );
    _lastPredictImminentFingerprint = fp;
    _predictImminentFailCount = 0;
    _predictImminentCooldownUntil = null;
  } catch (e) {
    _predictImminentFailCount++;
    AppDebugLog.predictImminent(
      'pending sync err=$e failCount=$_predictImminentFailCount',
    );
    if (_predictImminentFailCount >= _kPredictImminentFailThreshold) {
      _predictImminentCooldownUntil = DateTime.now().add(_kPredictImminentCooldown);
      AppDebugLog.predictImminent(
        'pending sync cooldown ${_kPredictImminentCooldown.inSeconds}s',
      );
    }
  }
}
