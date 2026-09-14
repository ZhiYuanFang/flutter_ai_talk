import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../data/cash_vip_models.dart';
import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/client_usage_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import 'feature_unlock/invite_code_dialog.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/feature_logo.dart';
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
    });
  }

  Future<void> _refreshAll() async {
    await ref.read(featureCatalogStateProvider.notifier).refresh();
    await ref.read(vipStatusProvider.notifier).refresh();
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
              ...catalog.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeatureUnlockCard(
                    item: item,
                    isVip: isVip,
                    onChanged: _refreshAll,
                  ),
                ),
              ),
            // 为底部悬浮月卡留出滚动空间
            const SizedBox(height: 140),
          ],
        ),
      ),
      bottomNavigationBar: _VipStickyBar(
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

/// 底部悬浮月卡：与功能列表滚动分离、含有效期文案。
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
      if (days < 0) return '月卡已过期';
      return '有效期至 $dateStr';
    }
    final days = vipProductAsync.valueOrNull?.durationDays ?? 30;
    if (days > 0) {
      return '开通后有效期 $days 天，可覆盖功能目录与预测事件锁（不含 UCG 入场门槛）';
    }
    return '开通月卡可覆盖功能目录与预测事件锁（不含 UCG 入场门槛）';
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
                  isVip ? _vipTitle : '开通月卡解锁所有功能',
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
                    child: const Text('去开通月卡'),
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

  bool get _isPrediction => item.featureId == kFeatureIdPredictionUnlock;

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
    // 一套 CTA：预测未达非叶子天花板则显示（含 VIP）；其它功能仅未有效开通时显示。
    final showUnlockCtas = _isPrediction
        ? shouldShowPredictionAccumulationCtas(item)
        : !unlocked;
    final accent = resolveFeatureColor(context, item);
    // 仅有效开通且有详情路由时挂整卡 onTap（未开通行靠 CTA，避免抢手势）。
    final detailRoute = unlocked ? _openedDetailRoute : null;

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
                    // 标题跟行功能色（与 AI Hub 字色政策对齐）。
                    Text(
                      item.title.isEmpty ? item.featureId : item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      // 介绍降透 accent，避免抢 CTA。
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
              if (_isPrediction && item.allowedCount != null)
                // 徽章：已激活 N / 已全部激活（N vs 服务端非叶子 total；非可见行数）
                Text(
                  item.predictionActivationBadgeCopy,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    // 状态跟功能色；未满略降透明以区分层次。
                    color: item.isPredictionFullyActivated
                        ? accent
                        : accent.withValues(alpha: 0.65),
                  ),
                )
              else if (unlocked)
                Text(
                  '已全部激活',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (showUnlockCtas)
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
                    child: _isPrediction
                        ? _PayPerUnitLabel(product: product, accent: accent)
                        : Text(
                            '支付开通 ¥${formatVipFenYuan(product.priceFen)}',
                            style: _kUnlockCtaTextStyle,
                          ),
                  ),
                if (item.supportsAd)
                  OutlinedButton(
                    style: _unlockCtaButtonStyle(accent),
                    onPressed: () =>
                        unawaited(_openAdDialog(context, ref, item)),
                    child: const Text('看广告', style: _kUnlockCtaTextStyle),
                  ),
                if (item.supportsInviteCode)
                  OutlinedButton(
                    style: _unlockCtaButtonStyle(accent),
                    onPressed: () =>
                        unawaited(_openInviteDialog(context, ref, item)),
                    child: const Text('输入邀请码激活', style: _kUnlockCtaTextStyle),
                  ),
              ],
            )
          else
            Text(
              // '开通方式：${featureUnlockMethodLabel(method)}'
              '${item.unlocked && item.expiresAt > 0 ? ' · ${featureRemainingDaysCopy(item.expiresAt)}' : (method == 'vip' ? (isVip && !_isPrediction ? ' · ${featureRemainingDaysCopy(ref.watch(vipStatusProvider).valueOrNull?.expireAt ?? 0)}' : '') : (item.unlocked ? ' · 永久' : ''))}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                // 已开通时效状态跟功能色。
                color: accent.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
    if (detailRoute == null) return card;
    // 整卡可点进详情；无箭头等额外暗示，仅 ripple 反馈。
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(detailRoute),
        child: card,
      ),
    );
  }

  Future<void> _openPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
    FeatureCatalogProduct product,
  ) async {
    final isPerUnit = item.featureId == kFeatureIdPredictionUnlock;
    final days = featureDurationCopy(product.durationDays);
    // 价串挂确认键右侧小字括号；正文不重复「价格：」。
    final priceLine = isPerUnit
        ? '¥${formatVipFenYuan(product.priceFen)}/个'
        : '¥${formatVipFenYuan(product.priceFen)}';
    final message = isPerUnit
        ? '永久 +1 条预测槽位'
        : '开通「${item.title}」有效期：$days';
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

  Future<void> _openAdDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
  ) async {
    // 非预测：正文带广告授予天数；缺字段弱化，不用付费 SKU 冒充。
    final String adMessage;
    if (item.featureId == kFeatureIdPredictionUnlock) {
      adMessage =
          '观看一段广告即可为「${item.title}」永久 +1 条。\n点击确定后视为已观看（演示）。';
    } else {
      final days = item.adDurationDays;
      final durationPart =
          days == null ? '' : '，有效期：${featureDurationCopy(days)}';
      adMessage =
          '观看一段广告即可开通「${item.title}」$durationPart。\n点击确定后视为已观看（演示）。';
    }
    final ok = await showGlassConfirmDialog(
      context,
      title: '看广告开通',
      message: adMessage,
      confirmLabel: '确定看广告',
      eventAccent: resolveFeatureColor(context, item),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(featureUnlockRepositoryProvider).completeAd(
            featureId: item.featureId,
            idempotencyKey:
                '${item.featureId}_${DateTime.now().millisecondsSinceEpoch}',
          );
      if (!context.mounted) return;
      showAppToast('已开通', tone: AppToastTone.success);
      await onChanged();
    } on ApiBusinessException catch (e) {
      if (!context.mounted) return;
      // 业务失败：展示服务端 message
      showAppToast(
        e.message.isNotEmpty ? e.message : '开通失败',
        tone: AppToastTone.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppToast('开通失败，请稍后重试', tone: AppToastTone.error);
    }
  }

  Future<void> _openInviteDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
  ) async {
    // 共享弹窗：获取邀请码 / 提交码（空码静默关闭）
    // 非预测：展示 inviteDurationDays；缺字段弱化，禁止用付费 SKU 天数。
    final String inviteBody;
    if (item.featureId == kFeatureIdPredictionUnlock) {
      inviteBody = '输入邀请码，激活1个预测槽位·永久';
    } else {
      final days = item.inviteDurationDays;
      inviteBody = days == null
          ? '输入邀请码激活「${item.title}」'
          : '输入邀请码激活「${item.title}」，有效期：${featureDurationCopy(days)}';
    }
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

/// 预测按次购买价签：现价 + 删除线原价 + /个。
class _PayPerUnitLabel extends StatelessWidget {
  const _PayPerUnitLabel({
    required this.product,
    required this.accent,
  });

  final FeatureCatalogProduct product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '¥${formatVipFenYuan(product.priceFen)}',
          style: _kUnlockCtaTextStyle.copyWith(color: accent),
        ),
        if (product.showOriginalPrice) ...[
          const SizedBox(width: 4),
          Text(
            '¥${formatVipFenYuan(product.originalPriceFen)}',
            style: _kUnlockCtaTextStyle.copyWith(
              decoration: TextDecoration.lineThrough,
              // 删除线原价：功能色降透明，保持次要。
              color: accent.withValues(alpha: 0.55),
            ),
          ),
        ],
        Text(
          '/个',
          style: _kUnlockCtaTextStyle.copyWith(color: accent),
        ),
      ],
    );
  }
}
