import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../data/cash_vip_models.dart';
import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/client_usage_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import 'ai_analysis_unlock.dart';
import 'feature_unlock/invite_code_dialog.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/feature_logo.dart';
import 'widgets/feeding_eligibility_progress_text.dart';
import 'widgets/settings_glass_panel.dart';

/// 开通更多功能（商业变现唯一入口页）。
class FeatureUnlockHubScreen extends ConsumerStatefulWidget {
  const FeatureUnlockHubScreen({super.key});

  @override
  ConsumerState<FeatureUnlockHubScreen> createState() =>
      _FeatureUnlockHubScreenState();
}

class _FeatureUnlockHubScreenState extends ConsumerState<FeatureUnlockHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
      unawaited(ref.read(vipStatusProvider.notifier).refresh());
      // 智能分析喂养资格：开通中心自行拉取，不依赖其它页预热。
      unawaited(
        ref.read(careAlertEligibilityStateProvider.notifier).ensureLoaded(),
      );
    });
  }

  Future<void> _refreshAll() async {
    // 目录 + VIP 状态 + 在售商品一并刷新，Admin 上架后下拉即可恢复底栏。
    await ref.read(featureCatalogStateProvider.notifier).refresh();
    await ref.read(vipStatusProvider.notifier).refresh();
    // care 喂养资格随下拉强制刷新。
    await ref
        .read(careAlertEligibilityStateProvider.notifier)
        .ensureLoaded(force: true);
    // 重建 product Future；失败只打日志，下拉仍结束（底栏按 hasValue 隐藏）。
    ref.invalidate(vipProductProvider);
    try {
      await ref.read(vipProductProvider.future);
    } catch (e) {
      AppDebugLog.cashVip('hub refresh product err=$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final onShell = tokens?.onShell ?? scheme.onSurface;
    final shell = tokens?.shellColor ?? scheme.surface;
    final catalog = ref.watch(featureCatalogStateProvider);
    final vip = ref.watch(vipStatusProvider).valueOrNull;
    final isVip = vip?.isVip == true;
    final vipProductAsync = ref.watch(vipProductProvider);
    // 仅在售商品拉取成功时展示 VIP sticky；下架 / 加载中 / 失败均不挂载。
    final showVipSticky = vipProductAsync.hasValue;

    return ClientUsageShowOnce(
      event: ClientUsageEvents.unlockHubShow,
      child: Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text('功能开通'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          children: [
            if (catalog.loading && !catalog.ready)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (catalog.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  catalog.failed ? '加载失败，下拉重试' : '暂无可开通功能',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onShell.withValues(alpha: 0.65)),
                ),
              )
            else
              // 过滤预测槽位商品；若过滤后为空则提示。
              ...() {
                final visible = catalog.items
                    .where((e) => e.featureId != kFeatureIdPredictionUnlock)
                    .toList();
                if (visible.isEmpty) {
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        catalog.failed ? '加载失败，下拉重试' : '暂无可开通功能',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: onShell.withValues(alpha: 0.65)),
                      ),
                    ),
                  ];
                }
                return visible
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeatureUnlockCard(
                          item: item,
                          isVip: isVip,
                          onChanged: _refreshAll,
                        ),
                      ),
                    )
                    .toList();
              }(),
            // 仅挂载 VIP sticky 时预留滚动空间，避免下架后底部空一大块。
            if (showVipSticky) const SizedBox(height: 140),
          ],
        ),
      ),
      bottomNavigationBar: !showVipSticky
          ? null
          : _VipStickyBar(
              isVip: isVip,
              expireAt: vip?.expireAt ?? 0,
              vipProductAsync: vipProductAsync,
              onShell: onShell,
              onOpenPurchase: !kVipPurchaseEnabled
                  ? null
                  : () => context.push('/vip/purchase'),
            ),
    ),
    );
  }
}

/// 底部悬浮 VIP 条：与功能列表滚动分离、含有效期文案。
class _VipStickyBar extends StatelessWidget {
  const _VipStickyBar({
    required this.isVip,
    required this.expireAt,
    required this.vipProductAsync,
    required this.onShell,
    this.onOpenPurchase,
  });

  final bool isVip;
  final int expireAt;
  final AsyncValue<CashVipProduct> vipProductAsync;
  final Color onShell;
  final VoidCallback? onOpenPurchase;

  String _validityCopy() {
    // 已 VIP：副文只强调到期日；倒计时已在主标题。
    if (isVip) {
      if (expireAt <= 0) return '长期有效';
      final end = DateTime.fromMillisecondsSinceEpoch(expireAt * 1000).toLocal();
      final dateStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      final days = end.difference(DateTime.now()).inDays;
      if (days < 0) return 'VIP 已过期';
      return '有效期至 $dateStr';
    }
    final days = vipProductAsync.valueOrNull?.durationDays ?? 30;
    if (days > 0) {
      return '开通后有效期 $days 天';
    }
    return '开通 VIP';
  }

  /// 已 VIP 主标题：VIP · 剩余 N 天 / 不足 1 天 / 永久 / 已过期。
  String get _vipTitle => 'VIP · ${featureRemainingDaysCopy(expireAt)}';

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).extension<AppVisualTokens>()?.shellColor ??
          Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SettingsGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isVip ? _vipTitle : '开通 VIP 解锁所有功能',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onShell,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _validityCopy(),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: onShell.withValues(alpha: 0.65),
                  ),
                ),
                if (!isVip) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onOpenPurchase,
                    child: const Text('去开通 VIP'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureUnlockCard extends ConsumerWidget {
  const _FeatureUnlockCard({
    required this.item,
    required this.isVip,
    required this.onChanged,
  });

  final FeatureCatalogItem item;
  final bool isVip;
  final Future<void> Function() onChanged;

  /// 已开通智能分析 / 成长轨迹 → 详情子页；其它无整卡跳转。
  String? get _openedDetailRoute {
    switch (item.featureId) {
      case kFeatureIdCareAlertSmartRemind:
        return '/prediction/ai-analysis/feeding';
      case kFeatureIdGrowthTrajectoryPredict:
        return '/prediction/ai-analysis/growth';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = isFeatureEffectivelyUnlocked(item: item, isVip: isVip);
    final method = displayUnlockMethod(item: item, isVip: isVip);
    final product = item.defaultProduct;
    final isCare = item.featureId == kFeatureIdCareAlertSmartRemind;
    // care 须持续喂养达标；成长轨迹等不受此闸。
    final careElig = isCare ? ref.watch(careAlertEligibilityStateProvider) : null;
    final careEligOk = !isCare || (careElig?.isQualified == true);
    // 未达标：整行开通 CTA 隐藏（含支付/邀请/试用）。
    final showUnlockCtas = !unlocked && careEligOk;
    final showTrial = shouldShowFreeTrialCta(item: item, isVip: isVip);
    final trialEnabled = showTrial && careEligOk;
    // 未达标提示（含已开通后资格回落）。
    final showUnqualifiedHint = isCare && !careEligOk;
    final accent = resolveFeatureColor(context, item);
    // 商业可访问且（非 care 或喂养达标）才可整卡进详情。
    final canEnter =
        canAccessFeatureDetail(item: item, isVip: isVip) && careEligOk;
    final detailRoute = canEnter ? _openedDetailRoute : null;

    final card = SettingsGlassPanel(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeatureLogo(logoUrl: item.logo, size: 32, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? item.featureId : item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: accent.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 已开通角标：care 须同时喂养达标，避免回落后仍显示「已开通」。
              if (unlocked && careEligOk)
                Text(
                  '已开通',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (showUnqualifiedHint)
            _careUnqualifiedFooter(
              elig: careElig!,
              accent: accent,
            )
          else if (showUnlockCtas)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.supportsPayment && product != null)
                  OutlinedButton(
                    style: _unlockCtaButtonStyle(accent),
                    onPressed: () => unawaited(
                      _openPaymentDialog(context, ref, item, product),
                    ),
                    child: Text(
                      '支付开通 ¥${formatVipFenYuan(product.priceFen)}',
                      style: _kUnlockCtaTextStyle,
                    ),
                  ),
                if (item.supportsInviteCode)
                  OutlinedButton(
                    style: _unlockCtaButtonStyle(accent),
                    onPressed: () =>
                        unawaited(_openInviteDialog(context, ref, item)),
                    child: const Text('输入邀请码激活', style: _kUnlockCtaTextStyle),
                  ),
                if (trialEnabled)
                  OutlinedButton(
                    style: _unlockCtaButtonStyle(accent),
                    onPressed: () => unawaited(
                      _openFreeTrial(context, ref, item),
                    ),
                    child: const Text('免费体验', style: _kUnlockCtaTextStyle),
                  ),
              ],
            )
          else
            Text(
              item.unlocked && item.expiresAt > 0
                  ? featureRemainingDaysCopy(item.expiresAt)
                  : (method == 'vip'
                      ? (isVip
                          ? featureRemainingDaysCopy(
                              ref.watch(vipStatusProvider).valueOrNull?.expireAt ??
                                  0,
                            )
                          : '')
                      : (item.unlocked ? '永久' : '')),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: accent.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
    if (detailRoute != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push(detailRoute),
          child: card,
        ),
      );
    }
    // care 未达标：整卡可点，Toast 提示（不进详情）。
    if (showUnqualifiedHint) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _toastCareUnqualified(careElig!),
          child: card,
        ),
      );
    }
    return card;
  }

  /// care 未达标底部：有 data 用进度文案，否则校验中 / 失败 / 短提示。
  Widget _careUnqualifiedFooter({
    required CareAlertEligibilityState elig,
    required Color accent,
  }) {
    if (elig.loading) {
      return Text(
        '正在校验喂养记录…',
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 13, color: accent.withValues(alpha: 0.85)),
      );
    }
    if (elig.failed) {
      return Text(
        '资格校验失败，下拉刷新重试',
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 13, color: accent.withValues(alpha: 0.85)),
      );
    }
    if (elig.data != null) {
      return FeedingEligibilityProgressText(
        eligibility: elig.data!,
        kind: FeedingEligibilityProgressKind.careAlert,
        textAlign: TextAlign.right,
        numberScale: 1.35,
        accent: accent,
        baseStyle: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: accent.withValues(alpha: 0.85),
        ),
      );
    }
    return Text(
      '未达到有效喂养门槛',
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 13, color: accent.withValues(alpha: 0.85)),
    );
  }

  /// 未达标整卡点击反馈。
  void _toastCareUnqualified(CareAlertEligibilityState elig) {
    if (elig.loading) {
      showAppToast('正在校验喂养记录…');
      return;
    }
    if (elig.failed) {
      showAppToast('资格校验失败，请下拉刷新重试');
      return;
    }
    final remaining = elig.data?.remainingDays;
    if (remaining != null && remaining > 0) {
      showAppToast('需累计有效喂养日后方可使用智能分析（还需 $remaining 天）');
      return;
    }
    showAppToast('需累计有效喂养日后方可使用智能分析');
  }

  Future<void> _openFreeTrial(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
  ) async {
    // care 须喂养达标才可 soft access 进详情。
    if (item.featureId == kFeatureIdCareAlertSmartRemind &&
        !ref.read(careAlertEligibilityStateProvider).isQualified) {
      showAppToast('需累计有效喂养日后方可使用智能分析');
      return;
    }
    final ok = await confirmFreeTrialDialog(context: context, feature: item);
    if (!ok || !context.mounted) return;
    final route = _openedDetailRoute;
    if (route == null) return;
    context.push(route);
  }

  Future<void> _openPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
    FeatureCatalogProduct product,
  ) async {
    final days = featureDurationCopy(product.durationDays);
    final priceLine = '¥${formatVipFenYuan(product.priceFen)}';
    final message = '开通「${item.title}」有效期：$days';
    final ok = await _showFeaturePayConfirmDialog(
      context,
      message: message,
      priceLine: priceLine,
      eventAccent: resolveFeatureColor(context, item),
      logoUrl: item.logo,
    );
    if (ok != true || !context.mounted || kIsWeb) return;
    final outcome =
        await ref.read(featurePaymentServiceProvider).purchase(product);
    if (!context.mounted) return;
    showAppToast(
      outcome.message.isEmpty
          ? (outcome.success ? '开通成功' : '支付未完成')
          : outcome.message,
      tone: outcome.success ? AppToastTone.success : AppToastTone.error,
    );
    if (outcome.success) await onChanged();
  }

  Future<void> _openInviteDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
  ) async {
    // 共享弹窗：获取邀请码 / 提交码（空码静默关闭）
    final days = item.inviteDurationDays;
    final inviteBody = days == null
        ? '输入邀请码激活「${item.title}」'
        : '输入邀请码激活「${item.title}」，有效期：${featureDurationCopy(days)}';
    final result = await showInviteCodeDialog(
      context,
      title: '输入邀请码',
      body: inviteBody,
      confirmLabel: '兑换',
      eventAccent: resolveFeatureColor(context, item),
      logoUrl: item.logo,
    );
    if (!context.mounted || result == null) return;
    if (result is InviteCodeDialogHowTo) {
      context.push('/features/invite-howto');
      return;
    }
    if (result is! InviteCodeDialogSubmitted) return;
    final code = result.code;
    // 空码点兑换：静默关闭
    if (code.isEmpty) return;
    try {
      await ref.read(featureUnlockRepositoryProvider).redeemInviteCode(
            code: code,
            featureId: item.featureId,
          );
      if (!context.mounted) return;
      showAppToast('兑换成功', tone: AppToastTone.success);
      await onChanged();
    } on ApiBusinessException catch (e) {
      if (!context.mounted) return;
      // 业务失败：展示服务端 message（如「不可使用自己的邀请码」）
      showAppToast(
        e.message.isNotEmpty ? e.message : '兑换失败',
        tone: AppToastTone.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppToast('兑换失败，请稍后重试', tone: AppToastTone.error);
    }
  }
}

/// 开通中心 CTA 字号（支付 / 广告 / 邀请统一）。
const _kUnlockCtaTextStyle = TextStyle(fontSize: 10);

/// 按功能色构造描边 CTA：字色与边框跟 accent。
ButtonStyle _unlockCtaButtonStyle(Color accent) {
  return OutlinedButton.styleFrom(
    foregroundColor: accent,
    side: BorderSide(color: accent.withValues(alpha: 0.55)),
    textStyle: _kUnlockCtaTextStyle,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  );
}

/// 支付确认：专用 glass 弹窗；确认键「去支付」+ 右侧小字括号价。
Future<bool?> _showFeaturePayConfirmDialog(
  BuildContext context, {
  required String message,
  required String priceLine,
  Color? eventAccent,
  String logoUrl = '',
}) {
  final actionLabel = kIsWeb ? '仅 App 可支付' : '去支付';
  return showGlassDialog<bool>(
    context: context,
    eventAccent: eventAccent,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      final onPrimary = scheme.onPrimary;
      final accent = eventAccent ?? scheme.primary;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FeatureLogo(logoUrl: logoUrl, size: 28, accent: accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '支付开通',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: glassText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: glassLabel,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('取消'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  // 确认钮跟已解析功能色（与 logo / 玻璃边一致）。
                  backgroundColor: accent,
                  foregroundColor: onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel),
                    Text(
                      ' ($priceLine)',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: onPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
