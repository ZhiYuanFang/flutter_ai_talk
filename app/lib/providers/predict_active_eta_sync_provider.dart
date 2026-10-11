import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/active_timing_eta.dart';
import '../data/models.dart';
import '../data/predict_active_eta_repository.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'event_catalog_notifier.dart';
import 'home_history_notifier.dart';
import 'prediction_range_history_provider.dart';
import 'session_provider.dart';
import 'settings_baby.dart';

final predictActiveEtaRepositoryProvider =
    Provider<PredictActiveEtaRepository>((ref) {
  return PredictActiveEtaRepository(ref.watch(authorizedApiClientProvider));
});

Future<void>? _predictActiveEtaSyncInFlight;
var _predictActiveEtaFailCount = 0;
DateTime? _predictActiveEtaCooldownUntil;
String? _lastPredictActiveEtaFingerprint;

const _kPredictActiveEtaFailThreshold = 3;
const _kPredictActiveEtaCooldown = Duration(seconds: 60);

/// 本机开始/停止计时或影响 duration 的变更后同步进行中 ETA。
///
/// [ref] 为 `Ref` 或 `WidgetRef`；延迟到下一 turn，避免 notifier 写入栈内读依赖断言。
Future<void> requestPredictActiveEtaPendingSync(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();
  return Future<void>(() => _requestPredictActiveEtaPendingSyncNow(ref));
}

Future<void> _requestPredictActiveEtaPendingSyncNow(dynamic ref) async {
  if (_predictActiveEtaSyncInFlight != null) {
    await _predictActiveEtaSyncInFlight;
    return;
  }
  final run = _syncPredictActiveEtaPendingOnce(ref);
  _predictActiveEtaSyncInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_predictActiveEtaSyncInFlight, run)) {
      _predictActiveEtaSyncInFlight = null;
    }
  }
}

Future<void> _syncPredictActiveEtaPendingOnce(dynamic ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final cooldown = _predictActiveEtaCooldownUntil;
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

    final homeItems = ref.read(homeHistoryProvider).items;
    final rangeItems = ref.read(predictionRangeHistoryProvider).items;
    final catalog = ref.read(eventCatalogProvider).items;
    final babyAsync =
        ref.read(settingsBabyProvider) as AsyncValue<BabyProfile>;
    final now = DateTime.now();
    final birth =
        babyAsync.asData?.value.birthDate ?? DateTime(now.year, 1, 1);

    final items = buildActiveTimingEtaItems(
      homeItems: homeItems,
      rangeItems: rangeItems,
      catalog: catalog,
      now: now,
      birthDate: birth,
    );

    final fp = items.isEmpty
        ? 'empty'
        : items.map((e) => e.fingerprintToken()).join('|');
    if (fp == _lastPredictActiveEtaFingerprint) return;

    await (ref.read(predictActiveEtaRepositoryProvider)
            as PredictActiveEtaRepository)
        .syncPending(deviceNo: dn, items: items);
    _lastPredictActiveEtaFingerprint = fp;
    _predictActiveEtaFailCount = 0;
    _predictActiveEtaCooldownUntil = null;
  } catch (e) {
    _predictActiveEtaFailCount++;
    AppDebugLog.predictActiveEta(
      'pending sync err=$e failCount=$_predictActiveEtaFailCount',
    );
    if (_predictActiveEtaFailCount >= _kPredictActiveEtaFailThreshold) {
      _predictActiveEtaCooldownUntil =
          DateTime.now().add(_kPredictActiveEtaCooldown);
      AppDebugLog.predictActiveEta(
        'pending sync cooldown ${_kPredictActiveEtaCooldown.inSeconds}s',
      );
    }
  }
}
