import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../data/feature_unlock_models.dart';
import '../providers/feature_unlock_provider.dart';
import 'feature_unlock/invite_code_dialog.dart';
import 'widgets/app_toast.dart';

/// 合格未开通：邀请码弹框；空码进开通中心；有码兑 care-alert。
Future<void> openCareAlertInviteUnlockDialog({
  required BuildContext context,
  required WidgetRef ref,
  required FeatureCatalogItem? careFeature,
}) async {
  final inviteDays = careFeature?.inviteDurationDays;
  final body = inviteDays == null
      ? '恭喜获得试用资格，输入邀请码即可兑换智能分析使用额度。'
      : '恭喜获得试用资格，输入邀请码即可兑换 ${featureDurationCopy(inviteDays)} 智能分析使用额度。';
  final result = await showInviteCodeDialog(
    context,
    title: '智能分析',
    body: body,
    confirmLabel: '开通',
    eventAccent: context.mounted
        ? resolveFeatureColor(context, careFeature)
        : null,
    logoUrl: careFeature?.logo ?? '',
  );
  if (!context.mounted || result == null) return;
  if (result is InviteCodeDialogHowTo) {
    context.push('/features/invite-howto');
    return;
  }
  if (result is! InviteCodeDialogSubmitted) return;
  final code = result.code;
  if (code.isEmpty) {
    context.push('/features/unlock');
    return;
  }
  try {
    await ref.read(featureUnlockRepositoryProvider).redeemInviteCode(
          code: code,
          featureId: kFeatureIdCareAlertSmartRemind,
        );
    if (!context.mounted) return;
    showAppToast('开通成功', tone: AppToastTone.success);
    await ref.read(featureCatalogStateProvider.notifier).refresh();
  } on ApiBusinessException catch (e) {
    if (!context.mounted) return;
    showAppToast(
      e.message.isNotEmpty ? e.message : '兑换失败',
      tone: AppToastTone.error,
    );
  } catch (_) {
    if (!context.mounted) return;
    showAppToast('兑换失败，请稍后重试', tone: AppToastTone.error);
  }
}

/// 合格未开通：邀请码弹框；空码进开通中心；有码兑成长轨迹。
Future<void> openGrowthTrajectoryInviteUnlockDialog({
  required BuildContext context,
  required WidgetRef ref,
  required FeatureCatalogItem? feature,
}) async {
  final inviteDays = feature?.inviteDurationDays;
  final body = inviteDays == null
      ? '恭喜获得试用资格，输入邀请码即可兑换成长轨迹预测使用额度。'
      : '恭喜获得试用资格，输入邀请码即可兑换 ${featureDurationCopy(inviteDays)} 成长轨迹预测使用额度。';
  final result = await showInviteCodeDialog(
    context,
    title: '成长轨迹',
    body: body,
    confirmLabel: '开通',
    eventAccent: context.mounted
        ? resolveFeatureColor(context, feature)
        : null,
    logoUrl: feature?.logo ?? '',
  );
  if (!context.mounted || result == null) return;
  if (result is InviteCodeDialogHowTo) {
    context.push('/features/invite-howto');
    return;
  }
  if (result is! InviteCodeDialogSubmitted) return;
  final code = result.code;
  if (code.isEmpty) {
    context.push('/features/unlock');
    return;
  }
  try {
    await ref.read(featureUnlockRepositoryProvider).redeemInviteCode(
          code: code,
          featureId: kFeatureIdGrowthTrajectoryPredict,
        );
    if (!context.mounted) return;
    showAppToast('开通成功', tone: AppToastTone.success);
    await ref.read(featureCatalogStateProvider.notifier).refresh();
  } on ApiBusinessException catch (e) {
    if (!context.mounted) return;
    showAppToast(
      e.message.isNotEmpty ? e.message : '兑换失败',
      tone: AppToastTone.error,
    );
  } catch (_) {
    if (!context.mounted) return;
    showAppToast('兑换失败，请稍后重试', tone: AppToastTone.error);
  }
}

/// Hub 已开通卡时效：功能限时 > VIP 到期 > 永久。
String featureHubEntitlementRemainingCopy({
  required FeatureCatalogItem? item,
  required bool isVip,
  required int vipExpireAt,
}) {
  if (item != null && item.unlocked) {
    if (item.expiresAt > 0) return featureRemainingDaysCopy(item.expiresAt);
    return '永久';
  }
  if (isVip) return featureRemainingDaysCopy(vipExpireAt);
  return '';
}
