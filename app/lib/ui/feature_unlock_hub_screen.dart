import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../data/cash_vip_models.dart';
import '../data/feature_unlock_models.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import '../ucg/ui/widgets/ucg_media_viewer.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/settings_glass_panel.dart';

String _resolveInviteGroupQrUrl(String raw, String apiBaseUrl) {
  final u = raw.trim();
  if (u.isEmpty) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final base = Uri.tryParse(apiBaseUrl.trim());
  if (base == null || !base.hasScheme) return u;
  return base.resolve(u.startsWith('/') ? u : '/$u').toString();
}
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
    final apiBase = ref.watch(authorizedApiClientProvider).baseUrl;
    final qrUrl =
        _resolveInviteGroupQrUrl(catalog.inviteGroupQrUrl, apiBase);

    return Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text(''),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          children: [
            if (qrUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _InviteGroupQrBlock(qrUrl: qrUrl, onShell: onShell),
              ),
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
            // 为底部悬浮月卡留出滚动空间
            const SizedBox(height: 140),
          ],
        ),
      ),
      // bottomNavigationBar: _VipStickyBar(
      //   isVip: isVip,
      //   expireAt: vip?.expireAt ?? 0,
      //   vipProductAsync: vipProductAsync,
      //   onShell: onShell,
      //   onOpenPurchase: !kVipPurchaseEnabled
      //       ? null
      //       : () => context.push('/vip/purchase'),
      // ),
    );
  }
}

/// 页级微信群二维码：文案居中在图正上方；加载失败则整块不渲染。
class _InviteGroupQrBlock extends StatefulWidget {
  const _InviteGroupQrBlock({
    required this.qrUrl,
    required this.onShell,
  });

  final String qrUrl;
  final Color onShell;

  @override
  State<_InviteGroupQrBlock> createState() => _InviteGroupQrBlockState();
}

class _InviteGroupQrBlockState extends State<_InviteGroupQrBlock> {
  /// 图片加载失败后隐藏整块（含文案），避免「有标题无图」。
  var _loadFailed = false;

  @override
  void didUpdateWidget(covariant _InviteGroupQrBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrUrl != widget.qrUrl) {
      _loadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) return const SizedBox.shrink();
    return SettingsGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '加入微信群获取邀请码',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.onShell.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          // 仅图可点：打开全屏可缩放预览，便于微信扫码。
          Center(
            child: GestureDetector(
              onTap: () => unawaited(
                showUcgPhotoLightbox(context, urls: [widget.qrUrl]),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.qrUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    // 首帧 errorBuilder 在 build 内，延后 setState 避免同步重建冲突。
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_loadFailed) {
                        setState(() => _loadFailed = true);
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部悬浮月卡：与功能列表滚动分离，含有效期文案。
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
    if (isVip && expireAt > 0) {
      final end = DateTime.fromMillisecondsSinceEpoch(expireAt * 1000).toLocal();
      final days = end.difference(DateTime.now()).inDays;
      final dateStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      if (days >= 0) {
        return '月卡有效期至 $dateStr（${featureRemainingDaysCopy(expireAt)}）';
      }
      return '月卡已过期';
    }
    final days = vipProductAsync.valueOrNull?.durationDays ?? 30;
    if (days > 0) {
      return '开通后有效期 $days 天，可覆盖功能目录与预测事件锁（不含 UCG 入场门槛）';
    }
    return '开通月卡可覆盖功能目录与预测事件锁（不含 UCG 入场门槛）';
  }

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
                  isVip ? '月卡已开通' : '开通月卡解锁所有功能',
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
    required this.onShell,
    required this.onChanged,
  });

  final FeatureCatalogItem item;
  final bool isVip;
  final Color onShell;
  final Future<void> Function() onChanged;

  bool get _isPrediction => item.featureId == kFeatureIdPredictionUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = isFeatureEffectivelyUnlocked(item: item, isVip: isVip);
    final method = displayUnlockMethod(item: item, isVip: isVip);
    final product = item.defaultProduct;
    // 一套 CTA：预测未达非叶子天花板则显示（含 VIP）；其它功能仅未有效开通时显示。
    final showUnlockCtas = _isPrediction
        ? shouldShowPredictionAccumulationCtas(item)
        : !unlocked;

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
                    if (_isPrediction && item.allowedCount != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.isPredictionFullAccess
                            ? '预测事项：永久条数待同步'
                            : '每次开通永久 +1 条预测事项',
                        style: TextStyle(
                          fontSize: 12,
                          color: onShell.withValues(alpha: 0.55),
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
                    color: item.isPredictionFullyActivated
                        ? Theme.of(context).colorScheme.primary
                        : onShell.withValues(alpha: 0.65),
                  ),
                )
              else if (unlocked)
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
          if (showUnlockCtas)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.supportsPayment && product != null)
                  OutlinedButton(
                    style: _kUnlockCtaButtonStyle,
                    onPressed: () => unawaited(
                      _openPaymentDialog(context, ref, item, product),
                    ),
                    child: _isPrediction
                        ? _PayPerUnitLabel(product: product, onShell: onShell)
                        : Text(
                            '支付开通 ¥${formatVipFenYuan(product.priceFen)}',
                            style: _kUnlockCtaTextStyle,
                          ),
                  ),
                if (item.supportsAd)
                  OutlinedButton(
                    style: _kUnlockCtaButtonStyle,
                    onPressed: () =>
                        unawaited(_openAdDialog(context, ref, item)),
                    child: const Text('看广告', style: _kUnlockCtaTextStyle),
                  ),
                if (item.supportsInviteCode)
                  OutlinedButton(
                    style: _kUnlockCtaButtonStyle,
                    onPressed: () =>
                        unawaited(_openInviteDialog(context, ref, item)),
                    child: const Text('输入邀请码开通', style: _kUnlockCtaTextStyle),
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
                color: onShell.withValues(alpha: 0.75),
              ),
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
    final isPerUnit = item.featureId == kFeatureIdPredictionUnlock;
    final days = featureDurationCopy(product.durationDays);
    // 价串挂确认键右侧小字括号；正文不重复「价格：」。
    final priceLine = isPerUnit
        ? '¥${formatVipFenYuan(product.priceFen)}/个'
        : '¥${formatVipFenYuan(product.priceFen)}';
    final message = isPerUnit
        ? '永久 +1 条预测事项'
        : '开通「${item.title}」有效期：$days';
    final ok = await _showFeaturePayConfirmDialog(
      context,
      message: message,
      priceLine: priceLine,
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
      message: item.featureId == kFeatureIdPredictionUnlock
          ? '观看一段广告即可为「${item.title}」永久 +1 条。\n点击确定后视为已观看（演示）。'
          : '观看一段广告即可开通「${item.title}」。\n点击确定后视为已观看（演示）。',
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
    // 码由弹层 State 持有；pop(String?) 带回，避免 await 后 dispose 与退场动画竞态
    final code = await showGlassDialog<String>(
      context: context,
      contentBuilder: (ctx) => _InviteCodeDialogBody(
        subtitle: item.featureId == kFeatureIdPredictionUnlock
            ? '输入好友邀请码，永久 +1 条预测事项'
            : '输入邀请码开通此功能',
      ),
    );
    if (code == null || code.isEmpty || !context.mounted) return;
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

/// 邀请码输入体：controller 生命周期绑定 State，对齐 `_GlassTextConfirmDialogBody`。
class _InviteCodeDialogBody extends StatefulWidget {
  const _InviteCodeDialogBody({required this.subtitle});

  final String subtitle;

  @override
  State<_InviteCodeDialogBody> createState() => _InviteCodeDialogBodyState();
}

class _InviteCodeDialogBodyState extends State<_InviteCodeDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '输入邀请码',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '请输入邀请码',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextButton(
                // 取消 / 无码：pop null
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ),
            Expanded(
              child: FilledButton(
                // 兑换：pop 修剪后的码（空串由外层忽略）
                onPressed: () =>
                    Navigator.pop(context, _controller.text.trim()),
                child: const Text('兑换'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 开通中心 CTA 字号（支付 / 广告 / 邀请统一）。
const _kUnlockCtaTextStyle = TextStyle(fontSize: 10);

final _kUnlockCtaButtonStyle = OutlinedButton.styleFrom(
  textStyle: _kUnlockCtaTextStyle,
  visualDensity: VisualDensity.compact,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
);

/// 支付确认：专用 glass 弹窗；确认键「去支付」+ 右侧小字括号价。
Future<bool?> _showFeaturePayConfirmDialog(
  BuildContext context, {
  required String message,
  required String priceLine,
}) {
  final actionLabel = kIsWeb ? '仅 App 可支付' : '去支付';
  return showGlassDialog<bool>(
    context: context,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      final onPrimary = scheme.onPrimary;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '支付开通',
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
                  backgroundColor: scheme.primary,
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
    required this.onShell,
  });

  final FeatureCatalogProduct product;
  final Color onShell;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '¥${formatVipFenYuan(product.priceFen)}',
          style: _kUnlockCtaTextStyle,
        ),
        if (product.showOriginalPrice) ...[
          const SizedBox(width: 4),
          Text(
            '¥${formatVipFenYuan(product.originalPriceFen)}',
            style: _kUnlockCtaTextStyle.copyWith(
              decoration: TextDecoration.lineThrough,
              color: onShell.withValues(alpha: 0.55),
            ),
          ),
        ],
        const Text('/个', style: _kUnlockCtaTextStyle),
      ],
    );
  }
}
