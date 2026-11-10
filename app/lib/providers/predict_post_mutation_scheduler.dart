import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../config/history_expect_resume_store.dart';
import '../data/event_catalog_state.dart';
import '../data/event_next_predictor.dart';
import '../data/history_expect_anchor_chain.dart';
import '../data/history_mapper.dart';
import '../data/models.dart';
import '../data/smart_prediction_rows.dart';
import 'device_no_notifier.dart';
import 'event_catalog_notifier.dart';
import 'history_latest_by_event_provider.dart';
import 'home_history_notifier.dart';
import 'predict_active_eta_sync_provider.dart';
import 'predict_imminent_sync_provider.dart';
import 'prediction_range_history_provider.dart';
import 'repositories.dart';
import 'session_provider.dart';
import 'settings_baby.dart';
import 'smart_prediction_provider.dart';

/// expect-batch 单批上限（对齐 Go twin）。
const kHistoryExpectBatchMaxItems = 200;

const _kExpectBatchFailThreshold = 3;
const _kExpectBatchCooldown = Duration(seconds: 60);

Future<void>? _schedulerInFlight;
var _schedulerDirty = false;
var _schedulerEpoch = 0;
String? _pendingResumeAnchorId;

var _expectBatchFailCount = 0;
DateTime? _expectBatchCooldownUntil;

/// 最近一次成功发出的 expect 指纹（WS 自回声跳过置脏）。
final Set<String> _lastExpectBatchFingerprints = <String>{};

/// 历史突变成功后入队统一静默管线（不 await 网络于 CRUD 热路径）。
///
/// [anchorHistoryId]：本趟起点行 id（非 pending）；用于 resume 游标。
Future<void> schedulePredictPostHistoryMutation(
  dynamic ref, {
  String? anchorHistoryId,
  bool resetCircuit = true,
}) {
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();
  final raw = anchorHistoryId?.trim();
  if (raw != null &&
      raw.isNotEmpty &&
      !isPendingHistoryId(raw) &&
      int.tryParse(raw) != null) {
    _pendingResumeAnchorId = raw;
  }
  if (resetCircuit) {
    _expectBatchFailCount = 0;
    _expectBatchCooldownUntil = null;
  }
  _schedulerDirty = true;
  _schedulerEpoch++;
  // 延迟到下一 turn，避免 notifier 写栈内读同源图断言
  return Future<void>(() => _pumpPredictPostHistoryMutation(ref));
}

/// 喂养页列表就绪后：有 resume 游标则续跑。
Future<void> maybeResumePredictPostHistoryMutation(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();
  return Future<void>(() => _maybeResumePredictPostHistoryMutationNow(ref));
}

/// WS upsert 后调用：指纹命中则视为 expect-batch 自回声（仍已 upsert）。
bool acknowledgeHistoryWsExpectEcho(HistoryRecord incoming) {
  if (_lastExpectBatchFingerprints.isEmpty) return false;
  final start = incoming.rawPayload['expectStartTime'];
  final end = incoming.rawPayload['expectEndTime'];
  final amt = incoming.rawPayload['expectAmount'];
  final fp = '${incoming.id}:$start:$end:$amt';
  return _lastExpectBatchFingerprints.contains(fp);
}

Future<void> _maybeResumePredictPostHistoryMutationNow(dynamic ref) async {
  final stored = await HistoryExpectResumeStore.load();
  if (stored == null || stored.isEmpty) return;
  if (isPendingHistoryId(stored)) {
    await HistoryExpectResumeStore.clear();
    AppDebugLog.predictPostMutation('resume clear pending id');
    return;
  }
  final home =
      (ref.read(homeHistoryProvider) as HomeHistoryState).items;
  final range =
      (ref.read(predictionRangeHistoryProvider) as PredictionRangeHistoryState)
          .items;
  final snap = mergeRealHistoryById(rangeItems: range, homeItems: home);
  final found = snap.any((r) => r.id == stored);
  if (!found) {
    await HistoryExpectResumeStore.clear();
    AppDebugLog.predictPostMutation('resume miss id=$stored cleared');
    return;
  }
  AppDebugLog.predictPostMutation('resume schedule id=$stored');
  await schedulePredictPostHistoryMutation(
    ref,
    anchorHistoryId: stored,
    resetCircuit: true,
  );
}

Future<void> _pumpPredictPostHistoryMutation(dynamic ref) async {
  if (_schedulerInFlight != null) {
    await _schedulerInFlight;
    return;
  }
  final run = _runPredictPostHistoryMutationLoop(ref);
  _schedulerInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_schedulerInFlight, run)) {
      _schedulerInFlight = null;
    }
  }
}

Future<void> _runPredictPostHistoryMutationLoop(dynamic ref) async {
  while (_schedulerDirty) {
    _schedulerDirty = false;
    final epochAtStart = _schedulerEpoch;
    final expectOk = await _runOnePredictPostHistoryMutation(
      ref,
      epochAtStart: epochAtStart,
    );
    // 熔断后不再因残留 dirty 紧循环
    if (!expectOk && _isExpectBatchCircuitOpen()) {
      AppDebugLog.predictPostMutation('circuit open stop dirty loop');
      break;
    }
  }
}

bool _isExpectBatchCircuitOpen() {
  final until = _expectBatchCooldownUntil;
  if (until == null) return false;
  return DateTime.now().isBefore(until);
}

Future<bool> _runOnePredictPostHistoryMutation(
  dynamic ref, {
  required int epochAtStart,
}) async {
  if (!ref.read(sessionProvider).isLoggedIn) return true;

  final dn = (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
          .asData
          ?.value
          ?.trim() ??
      '';
  if (dn.isEmpty) return true;

  final anchor = _pendingResumeAnchorId;
  if (anchor != null &&
      anchor.isNotEmpty &&
      !isPendingHistoryId(anchor)) {
    // 开跑前持久化 resume 游标
    await HistoryExpectResumeStore.save(anchor);
  }

  final home =
      (ref.read(homeHistoryProvider) as HomeHistoryState).items;
  final range =
      (ref.read(predictionRangeHistoryProvider) as PredictionRangeHistoryState)
          .items;
  final catalog =
      (ref.read(eventCatalogProvider) as EventCatalogState).items;
  final babyAsync = ref.read(settingsBabyProvider) as AsyncValue<BabyProfile>;
  final now = DateTime.now();
  final birth =
      babyAsync.asData?.value.birthDate ?? DateTime(now.year, 1, 1);
  final halfLife = halfLifeDaysForBirthDate(birth, now);

  final snap = mergeRealHistoryById(rangeItems: range, homeItems: home);
  final patches = buildHistoryExpectAnchorPatches(
    snapshot: snap,
    catalog: catalog,
    now: now,
    halfLifeDays: halfLife,
  );

  var expectStepOk = true;
  if (patches.isEmpty) {
    AppDebugLog.predictPostMutation('expect patches empty skip http');
  } else if (_isExpectBatchCircuitOpen()) {
    expectStepOk = false;
    AppDebugLog.predictPostMutation('expect-batch cooldown skip');
  } else {
    expectStepOk = await _postExpectPatchesChunked(
      ref,
      deviceNo: dn,
      patches: patches,
      epochAtStart: epochAtStart,
    );
  }

  // epoch 过期：丢弃本趟后续写，靠 dirty 重跑
  if (epochAtStart != _schedulerEpoch) {
    AppDebugLog.predictPostMutation('epoch stale after expect');
    return expectStepOk;
  }

  // 后续步 MAY 在 expect 失败后继续
  await requestHistoryLatestByEventSync(ref);
  // 触发本地预测可读
  try {
    ref.read(smartPredictionBundleProvider);
  } catch (_) {}
  await requestPredictImminentPendingSync(ref);
  await requestPredictActiveEtaPendingSync(ref);

  if (epochAtStart != _schedulerEpoch) {
    return expectStepOk;
  }

  if (expectStepOk && !_schedulerDirty) {
    await HistoryExpectResumeStore.clear();
    _pendingResumeAnchorId = null;
    AppDebugLog.predictPostMutation('pipeline ok resume cleared');
  } else if (!expectStepOk) {
    AppDebugLog.predictPostMutation('expect failed keep resume');
  }
  return expectStepOk;
}

Future<bool> _postExpectPatchesChunked(
  dynamic ref, {
  required String deviceNo,
  required List<HistoryExpectPatch> patches,
  required int epochAtStart,
}) async {
  final feed = ref.read(feedRepositoryProvider);
  final fps = <String>{};
  for (var i = 0; i < patches.length; i += kHistoryExpectBatchMaxItems) {
    if (epochAtStart != _schedulerEpoch) return false;
    final end = (i + kHistoryExpectBatchMaxItems < patches.length)
        ? i + kHistoryExpectBatchMaxItems
        : patches.length;
    final chunk = patches.sublist(i, end);
    final items = chunk.map((p) => p.toJsonItem()).toList();
    final ok = await feed.postHistoryExpectBatch(
      deviceNo: deviceNo,
      items: items,
    );
    if (!ok) {
      _expectBatchFailCount++;
      AppDebugLog.predictPostMutation(
        'expect-batch fail count=$_expectBatchFailCount chunk=$i',
      );
      if (_expectBatchFailCount >= _kExpectBatchFailThreshold) {
        _expectBatchCooldownUntil = DateTime.now().add(_kExpectBatchCooldown);
        AppDebugLog.predictPostMutation(
          'expect-batch cooldown ${_kExpectBatchCooldown.inSeconds}s',
        );
      }
      return false;
    }
    for (final p in chunk) {
      fps.add(p.fingerprint());
    }
  }
  _lastExpectBatchFingerprints
    ..clear()
    ..addAll(fps);
  _expectBatchFailCount = 0;
  _expectBatchCooldownUntil = null;
  AppDebugLog.predictPostMutation('expect-batch ok n=${patches.length}');
  return true;
}
