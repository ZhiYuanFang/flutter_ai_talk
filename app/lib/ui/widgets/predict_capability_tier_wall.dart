import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../data/feature_unlock_models.dart';
import '../../data/predict_capability_tier.dart';
import '../../providers/feature_unlock_provider.dart';
import '../../providers/predict_basic_feature_action_providers.dart';
import '../../providers/predict_pro_idea_provider.dart';
import '../../theme/app_color.dart';
import 'predict_basic_tier_demos.dart';
import 'predict_pro_idea_panel.dart';

/// 打开预测免费/Pro 全屏墙；[initialTier] 为中心起始档。
Future<void> showPredictCapabilityTierWall(
  BuildContext context, {
  required PredictCapabilityTier initialTier,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, secondary) {
      return PredictCapabilityTierWallPage(initialTier: initialTier);
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

/// 全屏两档墙：carousel 中卡放大；点遮罩关闭（无右上 ✕）。
class PredictCapabilityTierWallPage extends ConsumerStatefulWidget {
  const PredictCapabilityTierWallPage({
    super.key,
    required this.initialTier,
  });

  final PredictCapabilityTier initialTier;

  @override
  ConsumerState<PredictCapabilityTierWallPage> createState() =>
      _PredictCapabilityTierWallPageState();
}

class _PredictCapabilityTierWallPageState
    extends ConsumerState<PredictCapabilityTierWallPage> {
  @override
  void initState() {
    super.initState();
    // 进墙时预热 Pro 资格与想法列表（不挡基础档；本版不开通 CTA）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(predictProEligibilityStateProvider.notifier).ensureLoaded(),
      );
      // 每次进墙强制拉 list：服务端空列表时清空本地，不因已 loaded 跳过
      unawaited(
        ref.read(predictProIdeaListProvider.notifier).ensureLoaded(force: true),
      );
    });
  }

  void _dismiss() {
    Navigator.of(context).maybePop();
  }

  /// 先关墙，再按 kind 落地（关墙后本 State 可能 dispose，故先抓 router/notifier）。
  void _onBasicFeatureTap(PredictBasicFeatureDemoKind kind) {
    final router = GoRouter.of(context);
    final castReq =
        ref.read(predictionLandscapeCastRequestProvider.notifier);
    final voiceReq =
        ref.read(predictionVoiceEngageRequestProvider.notifier);
    Navigator.of(context).pop();
    // 等 dialog 卸掉再 push / 发 request
    Future.microtask(() {
      switch (kind) {
        // 智能估算下次：仅关墙
        case PredictBasicFeatureDemoKind.nextEstimate:
          break;
        // 家庭全员共享：进邀请家人页
        case PredictBasicFeatureDemoKind.familyShare:
          router.push('/settings/baby-share');
        case PredictBasicFeatureDemoKind.pushRemind:
          router.push('/settings/notifications');
        case PredictBasicFeatureDemoKind.homeWidget:
          router.push('/widgets/showcase');
        case PredictBasicFeatureDemoKind.trendChart:
          router.push('/trends');
        case PredictBasicFeatureDemoKind.xiaozhiSpeaker:
          router.push('/settings/xiaozhi-speaker');
        case PredictBasicFeatureDemoKind.landscapeCast:
          castReq.request();
        case PredictBasicFeatureDemoKind.voiceBall:
          voiceReq.request();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(featureCatalogStateProvider);
    final pair = predictCapabilityItems(catalog);
    final media = MediaQuery.of(context);
    final cardHeight = media.size.height * 0.72;

    // 底层全屏可点关；上层卡片接收滑动，避免全屏 Material 吞 barrier
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Center(
              child: SizedBox(
                height: cardHeight,
                child: CarouselSlider.builder(
                  itemCount: PredictCapabilityTier.values.length,
                  options: CarouselOptions(
                    height: cardHeight,
                    viewportFraction: 0.78,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.22,
                    enableInfiniteScroll: false,
                    initialPage: widget.initialTier.index,
                  ),
                  itemBuilder: (context, index, realIdx) {
                    final tier = PredictCapabilityTier.values[index];
                    return _tierSlide(
                      tier: tier,
                      pro: pair.pro,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierSlide({
    required PredictCapabilityTier tier,
    required FeatureCatalogItem? pro,
  }) {
    final accent = _tierAccent(context, tier, pro: pro);
    final footer = resolvePredictTierFooter(tier: tier, pro: pro);
    final title = _tierTitle(tier, pro: pro);
    final isBasic = tier == PredictCapabilityTier.free;
    // Pro：网络 logo；基础版：本地 pre_basic
    final proLogoUrl = switch (tier) {
      PredictCapabilityTier.free => '',
      PredictCapabilityTier.pro => pro?.logo.trim() ?? '',
    };
    final showProNetwork = proLogoUrl.isNotEmpty &&
        (proLogoUrl.startsWith('http://') ||
            proLogoUrl.startsWith('https://'));
    // Pro 仍 MD；基础版走结构化 demo 列表
    final proBodyMd = !isBasic
        ? () {
            final d = pro?.description.trim() ?? '';
            return d.isEmpty ? kPredictProTierBodyMarkdownFallback : d;
          }()
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: AppColor.panelGlassGradient(context, accent: accent),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isBasic) ...[
                      _tierLogoFrame(
                        child: Image.asset(
                          kPredictFreeTierLogoAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (showProNetwork) ...[
                      _tierLogoFrame(
                        child: CachedNetworkImage(
                          imageUrl: proLogoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: accent.withValues(alpha: 0.12),
                            child: Icon(Icons.image_not_supported_outlined,
                                color: accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textOnPanelGlass(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isBasic
                          ? SingleChildScrollView(
                              child: PredictBasicFeatureList(
                                accent: accent,
                                onItemTap: _onBasicFeatureTap,
                              ),
                            )
                          : _ProTierBody(
                              proBodyMd: proBodyMd,
                              accent: accent,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 本版仅状态标签，非可点按钮（浅灰底 + 黑字）；想法入口在卡内
          // Pro 敬请期待可同行挂 catalog 月价小字（无价则空）
          _FooterStatusLabel(
            label: predictTierFooterLabel(footer),
            priceHint: predictProComingSoonPriceHint(
              footer: footer,
              pro: pro,
            ),
          ),
        ],
      ),
    );
  }

  /// Free/Pro 同规则小图框（固定高度 + contain，避免铺满宽）。
  Widget _tierLogoFrame({required Widget child}) {
    return Center(
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  Color _tierAccent(
    BuildContext context,
    PredictCapabilityTier tier, {
    required FeatureCatalogItem? pro,
  }) {
    switch (tier) {
      case PredictCapabilityTier.free:
        return Theme.of(context).colorScheme.primary;
      case PredictCapabilityTier.pro:
        return resolveFeatureColor(context, pro);
    }
  }

  String _tierTitle(
    PredictCapabilityTier tier, {
    required FeatureCatalogItem? pro,
  }) {
    switch (tier) {
      case PredictCapabilityTier.free:
        return '基础版';
      case PredictCapabilityTier.pro:
        final t = pro?.title.trim() ?? '';
        return t.isEmpty ? '预测能力 Pro' : t;
    }
  }

}

/// Pro 档：catalog MD + 想法区（空态/有数据均钉底 CTA）。
class _ProTierBody extends ConsumerWidget {
  const _ProTierBody({
    required this.proBodyMd,
    required this.accent,
  });

  final String proBodyMd;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideas = ref.watch(predictProIdeaListProvider);
    final empty = ideas.loaded && ideas.items.isEmpty;

    final md = GestureDetector(
      // Pro MD：吞点，避免误触关墙
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: _TierMarkdownBody(
        data: proBodyMd,
        accent: accent,
      ),
    );

    if (!ideas.loaded && ideas.loading) {
      return Column(
        children: [
          Expanded(child: SingleChildScrollView(child: md)),
          PredictProIdeaPanel(accent: accent),
        ],
      );
    }

    if (empty || (!ideas.loaded && ideas.errorMessage != null)) {
      // 空态（或失败当空）：MD 可滚，圆钮钉卡内底
      return Column(
        children: [
          Expanded(child: SingleChildScrollView(child: md)),
          const SizedBox(height: 12),
          PredictProIdeaPanel(accent: accent),
        ],
      );
    }

    // 有想法：MD+列表可滚；「我有更多想法」+ 小字钉卡内底
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                md,
                const SizedBox(height: 14),
                PredictProIdeaPanel(
                  accent: accent,
                  showBottomCta: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        PredictProIdeaMoreCta(accent: accent),
      ],
    );
  }
}

/// Pro 墙内 Markdown：跟玻璃字色，左对齐。
class _TierMarkdownBody extends StatelessWidget {
  const _TierMarkdownBody({
    required this.data,
    required this.accent,
  });

  final String data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // panelGlass 正文/次文原子；标题跟档位 accent
    final onGlass = AppColor.textOnPanelGlass(context);
    final muted = AppColor.textOnPanelGlassMuted(context);
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.45,
      color: muted,
    );
    final headingStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: accent,
      height: 1.35,
    );
    // 无 · marker，省横向；emoji 作行首标签；常用节点全绑主题色
    final config = MarkdownConfig(
      configs: [
        PConfig(textStyle: bodyStyle),
        H1Config(style: headingStyle.copyWith(fontSize: 18)),
        H2Config(style: headingStyle.copyWith(fontSize: 16)),
        H3Config(style: headingStyle.copyWith(fontSize: 15)),
        ListConfig(
          marginLeft: 0,
          marginBottom: 6,
          marker: (isOrdered, depth, index) => const SizedBox.shrink(),
        ),
        LinkConfig(
          style: bodyStyle.copyWith(
            color: accent,
            decoration: TextDecoration.underline,
          ),
        ),
        CodeConfig(
          style: bodyStyle.copyWith(
            color: onGlass,
            backgroundColor: accent.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
    return MarkdownWidget(
      data: data,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      config: config,
    );
  }
}

/// 非按钮状态脚：浅灰底 + 黑字（不跟档位 accent）；可选同行月价小字。
class _FooterStatusLabel extends StatelessWidget {
  const _FooterStatusLabel({
    required this.label,
    this.priceHint = '',
  });

  final String label;

  /// Pro 敬请期待后的 `¥x/月`；空则不渲染。
  final String priceHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final hint = priceHint.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // 浅灰底
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        // 不可点：无 InkWell / GestureDetector
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  // 近黑正文
                  color: onSurface,
                ),
              ),
              if (hint.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    // 略淡辅信息
                    color: onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
