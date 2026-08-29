import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/cash_vip_models.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
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

    return Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text('开通更多功能'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                    onShell: onShell,
                    onChanged: _refreshAll,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SettingsGlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '开通月卡解锁所有功能',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onShell,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '月卡可覆盖功能目录与预测事件锁（不含 UCG 入场门槛）',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: onShell.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: !kVipPurchaseEnabled
                        ? null
                        : () => context.push('/vip/purchase'),
                    child: const Text('去开通月卡'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureUnlockCard extends ConsumerWidget {
  const _FeatureUnlockCard({
    required this.item,
    required this.isVip,
    required this.onShell,
    required this.onChanged,
  });

  final FeatureCatalogItem item;
  final bool isVip;
  final Color onShell;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = isFeatureEffectivelyUnlocked(item: item, isVip: isVip);
    final method = displayUnlockMethod(item: item, isVip: isVip);
    final product = item.defaultProduct;

    return SettingsGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? item.featureId : item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: onShell,
                          ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: onShell.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (item.featureId == kFeatureIdPredictionUnlock &&
                        item.allowedCount != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.isPredictionFullAccess
                            ? (item.expiresAt > 0
                                ? '预测事项：期限内全部可看'
                                : '预测事项：全部可看')
                            : '当前可展示预测事项：${item.allowedCount} 个',
                        style: TextStyle(
                          fontSize: 12,
                          color: onShell.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (unlocked)
                Text(
                  '已开通',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (unlocked)
            Text(
              '开通方式：${featureUnlockMethodLabel(method)}'
              '${item.unlocked && item.expiresAt > 0 ? ' · ${featureRemainingDaysCopy(item.expiresAt)}' : (method == 'vip' ? '' : (item.unlocked ? ' · 永久' : ''))}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: onShell.withValues(alpha: 0.75),
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.supportsPayment && product != null)
                  OutlinedButton(
                    onPressed: () => unawaited(
                      _openPaymentDialog(context, ref, item, product),
                    ),
                    child: Text(
                      '支付开通 ¥${formatVipFenYuan(product.priceFen)}',
                    ),
                  ),
                if (item.supportsAd)
                  OutlinedButton(
                    onPressed: () => unawaited(_openAdDialog(context, ref, item)),
                    child: const Text('看广告'),
                  ),
                if (item.supportsInviteCode)
                  OutlinedButton(
                    onPressed: () =>
                        unawaited(_openInviteDialog(context, ref, item)),
                    child: const Text('激活码'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _openPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
    FeatureCatalogProduct product,
  ) async {
    final days = featureDurationCopy(product.durationDays);
    final ok = await showGlassConfirmDialog(
      context,
      title: '支付开通',
      message: '开通「${item.title}」有效期：$days\n'
          '价格：¥${formatVipFenYuan(product.priceFen)}',
      confirmLabel: kIsWeb ? '仅 App 可支付' : '去支付',
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
    final ok = await showGlassConfirmDialog(
      context,
      title: '看广告开通',
      message: '观看一段广告即可开通「${item.title}」。\n'
          '点击确定后视为已观看（演示）。',
      confirmLabel: '确定看广告',
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
    } catch (e) {
      if (!context.mounted) return;
      showAppToast('开通失败，请稍后重试', tone: AppToastTone.error);
    }
  }

  Future<void> _openInviteDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureCatalogItem item,
  ) async {
    final controller = TextEditingController();
    final ok = await showGlassDialog<bool>(
      context: context,
      contentBuilder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '输入激活码',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '可向群主获取免费激活码',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '请输入激活码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('兑换'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    final code = controller.text.trim();
    controller.dispose();
    if (ok != true || code.isEmpty || !context.mounted) return;
    try {
      await ref.read(featureUnlockRepositoryProvider).redeemInviteCode(
            code: code,
            featureId: item.featureId,
          );
      if (!context.mounted) return;
      showAppToast('兑换成功', tone: AppToastTone.success);
      await onChanged();
    } catch (e) {
      if (!context.mounted) return;
      showAppToast('兑换失败，请检查激活码', tone: AppToastTone.error);
    }
  }
}
