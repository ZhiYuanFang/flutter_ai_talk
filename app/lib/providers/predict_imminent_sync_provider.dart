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

const _kPredictImminentFailThreshold = 3;
const _kPredictImminentCooldown = Duration(seconds: 60);

/// 本机喂养记录 / 间隔变更后显式请求 pending 同步（先重算再 PUT）。
///
/// [ref] 为 `Ref`、`WidgetRef` 或 [ProviderContainer]。须延迟到下一 event-loop turn：
/// notifier 写入栈内 `ref.read` 同源依赖图会断言失败（同 [scheduleHomeWidgetSync]）。
/// 不做内容指纹跳过：合格进入且非熔断时每次都 PUT（允许 body 与上次相同）。
Future<void> requestPredictImminentPendingSync(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();
  return Future<void>(() => _requestPredictImminentPendingSyncNow(ref));
}

Future<void> _requestPredictImminentPendingSyncNow(dynamic ref) async {
  if (_predictImminentSyncInFlight != null) {
    await _predictImminentSyncInFlight;
    return;
  }
  final run = _syncPredictImminentPendingOnce(ref);
  _predictImminentSyncInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_predictImminentSyncInFlight, run)) {
      _predictImminentSyncInFlight = null;
    }
  }
}

Future<void> _syncPredictImminentPendingOnce(dynamic ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final cooldown = _predictImminentCooldownUntil;
  if (cooldown != null && DateTime.now().isBefore(cooldown)) {
    return;
  }

  try {
    // dynamic ref 上须先 as AsyncValue，再 asData（见 project.md）
    final dn = (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
            .asData
            ?.value
            ?.trim() ??
        '';
    if (dn.isEmpty) return;

    // pending 用全量子/根预测（非卡上胜出子集）；空列表也上报以清空
    final predictions =
        ref.read(smartPendingPredictionsProvider) as List<EventNextPrediction>;

    // dynamic 上读 Provider 亦先收成仓库类型再调 syncPending
    await (ref.read(predictImminentRepositoryProvider)
            as PredictImminentRepository)
        .syncPending(
      deviceNo: dn,
      predictions: predictions,
    );
    _predictImminentFailCount = 0;
    _predictImminentCooldownUntil = null;
  } catch (e) {
    _predictImminentFailCount++;
    AppDebugLog.predictImminent(
      'pending sync err=$e failCount=$_predictImminentFailCount',
    );
    if (_predictImminentFailCount >= _kPredictImminentFailThreshold) {
      _predictImminentCooldownUntil =
          DateTime.now().add(_kPredictImminentCooldown);
      AppDebugLog.predictImminent(
        'pending sync cooldown ${_kPredictImminentCooldown.inSeconds}s',
      );
    }
  }
}
