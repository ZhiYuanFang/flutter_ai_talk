import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/home_history_store.dart';
import '../data/satisfaction_survey_repository.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/session_provider.dart';
import 'home_satisfaction_survey_sheet.dart';

/// 主壳启动弹窗（notify、version）结束后的问卷。同一次挂载只由调用方调一次。
Future<void> maybeOfferHomeSatisfactionSurvey({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final deviceNo =
      ref.read(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  if (deviceNo.isEmpty) {
    AppDebugLog.survey('skip empty deviceNo');
    return;
  }
  // 内存或磁盘有喂养记录才请求；Web 无磁盘，只看内存。
  final memoryItems = ref.read(homeHistoryProvider).items;
  var hasHistory = memoryItems.isNotEmpty;
  if (!hasHistory) {
    final snapshot = await HomeHistoryStore.loadSnapshot(deviceNo);
    hasHistory = snapshot.items.isNotEmpty;
  }
  if (!hasHistory) {
    AppDebugLog.survey('skip no history cache');
    return;
  }
  if (!context.mounted) return;

  final repo = SatisfactionSurveyRepository(
    ref.read(authorizedApiClientProvider),
  );
  late final SatisfactionSurveyCurrent current;
  try {
    current = await repo.fetchCurrent();
  } catch (e) {
    AppDebugLog.survey('current err=$e');
    return;
  }
  if (!context.mounted) return;
  // 只看 show。关活动或已提交时 campaignId 仍可能有值。
  if (!current.show) return;
  await showHomeSatisfactionSurveySheet(context, current: current, repo: repo);
}
