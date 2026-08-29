import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cash_vip_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../theme/app_visual_tokens.dart';
import 'widgets/app_toast.dart';

/// VIP 购买页：现价 / 可选划线原价 + 平台支付开通。
class VipPurchaseScreen extends ConsumerStatefulWidget {
  const VipPurchaseScreen({super.key});

  @override
  ConsumerState<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends ConsumerState<VipPurchaseScreen>
    with WidgetsBindingObserver {
  var _paying = false;
  var _awaitingAlipayReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_awaitingAlipayReturn || _paying) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    unawaited(_pollAfterAlipayReturn());
  }

  Future<void> _pollAfterAlipayReturn() async {
    setState(() => _paying = true);
    try {
      final vip = await ref.read(vipPaymentServiceProvider).pollStatusUntilVip();
      await ref.read(vipStatusProvider.notifier).refresh();
      if (!mounted) return;
      if (vip) {
        _awaitingAlipayReturn = false;
        showAppToast('VIP 已开通');
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _onPay(CashVipProduct product) async {
    if (_paying) return;
    setState(() => _paying = true);
    if (defaultTargetPlatform == TargetPlatform.android) {
      _awaitingAlipayReturn = true;
    }
    try {
      final outcome =
          await ref.read(vipPaymentServiceProvider).purchase(product);
      await ref.read(vipStatusProvider.notifier).refresh();
      if (!mounted) return;
      if (outcome.cancelled) {
        _awaitingAlipayReturn = false;
        showAppToast(outcome.message);
        return;
      }
      if (outcome.success) {
        _awaitingAlipayReturn = false;
        showAppToast(
          outcome.message.isEmpty ? 'VIP 已开通' : outcome.message,
        );
        Navigator.of(context).pop(true);
        return;
      }
      showAppToast(
        outcome.message.isEmpty ? '开通失败' : outcome.message,
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final shell = tokens?.shellColor ?? scheme.surface;
    final onShell = tokens?.onShell ?? scheme.onSurface;
    final productAsync = ref.watch(vipProductProvider);

    return Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text('开通 VIP'),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          onShell: onShell,
          onRetry: () => ref.invalidate(vipProductProvider),
        ),
        data: (product) => _PurchaseBody(
          product: product,
          onShell: onShell,
          paying: _paying,
          onPay: () => unawaited(_onPay(product)),
          catalogTitles: ref
              .watch(featureCatalogStateProvider)
              .items
              .map((e) => e.title.trim().isEmpty ? e.featureId : e.title)
              .where((t) => t.isNotEmpty)
              .toList(),
        ),
      ),
    );
  }
}

class _PurchaseBody extends StatelessWidget {
  const _PurchaseBody({
    required this.product,
    required this.onShell,
    required this.paying,
    required this.onPay,
    this.catalogTitles = const [],
  });

  final CashVipProduct product;
  final Color onShell;
  final bool paying;
  final VoidCallback onPay;
  final List<String> catalogTitles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = formatVipFenYuan(product.priceFen);
    final payLabel = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => '通过 Apple 支付开通',
      TargetPlatform.android => '支付宝开通',
      _ => '开通 VIP',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            product.title.isEmpty ? '胖宝 VIP' : product.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onShell,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            product.durationDays > 0
                ? '开通后可享受 ${product.durationDays} 天会员权益'
                : '开通后可享受会员权益',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: onShell.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  height: 1,
                ),
              ),
              if (product.showOriginalPrice) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '¥${formatVipFenYuan(product.originalPriceFen)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: onShell.withValues(alpha: 0.45),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (catalogTitles.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              '月卡包含的更多功能',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onShell,
              ),
            ),
            const SizedBox(height: 8),
            ...catalogTitles.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 14,
                          color: onShell.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '不含 UCG 广场入场门槛（仍须有效喂养记录达标）',
              style: TextStyle(
                fontSize: 12,
                color: onShell.withValues(alpha: 0.5),
              ),
            ),
          ],
          const Spacer(),
          if (kIsWeb)
            Text(
              '请使用 iOS / Android App 完成支付',
              textAlign: TextAlign.center,
              style: TextStyle(color: onShell.withValues(alpha: 0.65)),
            )
          else
            FilledButton(
              onPressed: paying ? null : onPay,
              child: paying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(payLabel),
            ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onShell, required this.onRetry});

  final Color onShell;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '商品加载失败',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onShell,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
