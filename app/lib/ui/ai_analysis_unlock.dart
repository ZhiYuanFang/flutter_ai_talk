import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/cash_vip_models.dart';
import '../data/feature_unlock_models.dart';
import '../providers/feature_unlock_provider.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

/// 合格未开通：功能介绍 + 标价支付；其它方式进开通中心（无邀请输入框）。
Future<void> openCareAlertInviteUnlockDialog({
  required BuildContext context,
  required WidgetRef ref,
  required FeatureCatalogItem? careFeature,
}) {
  return _openFeatureIntroPayDialog(
    context: context,
    ref: ref,
    feature: careFeature,
    title: '智能分析',
    fallbackDesc: '基于喂养记录生成值得留意的智能分析，帮助家长把握宝宝近况。',
  );
}

/// 未开通成长轨迹：同构介绍 + 标价支付。
Future<void> openGrowthTrajectoryInviteUnlockDialog({
  required BuildContext context,
  required WidgetRef ref,
  required FeatureCatalogItem? feature,
}) {
  return _openFeatureIntroPayDialog(
    context: context,
    ref: ref,
    feature: feature,
    title: '成长轨迹',
    fallbackDesc: '结合宝宝近况预测成长轨迹，帮助家长提前了解可能要注意的事项。',
  );
}

Future<void> _openFeatureIntroPayDialog({
  required BuildContext context,
  required WidgetRef ref,
  required FeatureCatalogItem? feature,
  required String title,
  required String fallbackDesc,
}) async {
  final desc = (feature?.description.trim().isNotEmpty == true)
      ? feature!.description.trim()
      : fallbackDesc;
  final product = feature?.defaultProduct;
  final accent = context.mounted ? resolveFeatureColor(context, feature) : null;
  final payLabel = feature?.payPriceLabel ?? '支付开通';

  final action = await showGlassDialog<_IntroPayAction>(
    context: context,
    eventAccent: accent,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      final btnAccent = accent ?? scheme.primary;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, _IntroPayAction.otherWays),
                style: TextButton.styleFrom(
                  foregroundColor: glassLabel,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('其它方式开通'),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: btnAccent,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: product == null || !feature!.supportsPayment
                    ? null
                    : () => Navigator.pop(ctx, _IntroPayAction.pay),
                child: Text(payLabel),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (!context.mounted || action == null) return;
  if (action == _IntroPayAction.otherWays) {
    context.push('/features/unlock');
    return;
  }
  if (action != _IntroPayAction.pay || product == null) return;
  if (kIsWeb) {
    showAppToast('请在 App 内完成支付', tone: AppToastTone.error);
    return;
  }
  final outcome =
      await ref.read(featurePaymentServiceProvider).purchase(product);
  if (!context.mounted) return;
  showAppToast(
    outcome.message.isEmpty
        ? (outcome.success ? '开通成功' : '支付未完成')
        : outcome.message,
    tone: outcome.success ? AppToastTone.success : AppToastTone.error,
  );
  if (outcome.success) {
    await ref.read(featureCatalogStateProvider.notifier).refresh();
  }
}

enum _IntroPayAction { pay, otherWays }

/// 免费体验确认：每位用户仅一次；确认后由调用方进入详情（不写库）。
Future<bool> confirmFreeTrialDialog({
  required BuildContext context,
  required FeatureCatalogItem? feature,
  String title = '免费体验',
}) async {
  final ok = await showGlassConfirmDialog(
    context,
    title: title,
    message: '每位用户仅有一次免费体验机会，成功体验后可享 24 小时使用权。确认开始体验？',
    cancelLabel: '取消',
    confirmLabel: '体验',
    eventAccent: context.mounted ? resolveFeatureColor(context, feature) : null,
  );
  return ok == true;
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

/// 分转元展示（与开通中心一致）。
String formatFeaturePayFenYuan(int fen) => formatVipFenYuan(fen);
