import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../providers/client_usage_provider.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/home_pager.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'ai_analysis_unlock.dart';
import 'widgets/feature_logo.dart';
import 'widgets/feeding_eligibility_progress_text.dart';

/// AI 分析 Hub：资格门 + 极简入口（业务在子页）。
class AiAnalysisScreen extends ConsumerStatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Hub 仅资格 + catalog；不拉 daily / ensureLatest。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(careAlertEligibilityStateProvider.notifier).ensureLoaded(),
      );
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shell = tokens?.shellColor ?? Theme.of(context).colorScheme.surface;
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;

    return ClientUsageShowOnce(
      event: ClientUsageEvents.aiAnalysisShow,
      child: Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text('AI分析'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          _HubFeedingCard(),
          SizedBox(height: 14),
          _HubGrowthCard(),
        ],
      ),
    ),
    );
  }
}

/// Hub 喂养卡：门闸 / 已开通进子页。
class _HubFeedingCard extends ConsumerWidget {
  const _HubFeedingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elig = ref.watch(careAlertEligibilityStateProvider);
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    final vipExpire =
        ref.watch(vipStatusProvider).valueOrNull?.expireAt ?? 0;
    final careFeature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdCareAlertSmartRemind);
    final unlocked =
        isFeatureEffectivelyUnlocked(item: careFeature, isVip: isVip);
    final accent = resolveFeatureColor(context, careFeature);

    Widget body;
    VoidCallback? onCardTap;
    String? entitlementCopy;

    if (!elig.isQualified) {
      if (elig.loading) {
        body = _hubMuted(context, '正在校验喂养记录…', accent);
      } else if (elig.failed) {
        onCardTap = () => unawaited(
              ref
                  .read(careAlertEligibilityStateProvider.notifier)
                  .ensureLoaded(force: true),
            );
        body = _hubMuted(context, '资格校验失败，点击重试', accent);
      } else if (elig.data != null) {
        onCardTap = () {
          ref
              .read(homePagerRequestProvider.notifier)
              .requestPage(HomePagerPage.feeding);
          context.go('/home');
        };
        body = Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: FeedingEligibilityProgressText(
            eligibility: elig.data!,
            kind: FeedingEligibilityProgressKind.careAlert,
            textAlign: TextAlign.start,
            numberScale: 1.65,
            accent: accent,
          ),
        );
      } else {
        onCardTap = () {
          ref
              .read(homePagerRequestProvider.notifier)
              .requestPage(HomePagerPage.feeding);
          context.go('/home');
        };
        body = _hubMuted(context, '需累计有效喂养日以激活值得留意', accent);
      }
    } else if (!unlocked) {
      onCardTap = () => unawaited(
            openCareAlertInviteUnlockDialog(
              context: context,
              ref: ref,
              careFeature: careFeature,
            ),
          );
      body = _UnlockHeartbeatPrompt(accent: accent);
    } else {
      entitlementCopy = featureHubEntitlementRemainingCopy(
        item: careFeature,
        isVip: isVip,
        vipExpireAt: vipExpire,
      );
      onCardTap = () => context.push('/prediction/ai-analysis/feeding');
      body = _hubMuted(context, '点击进入，生成今日值得留意', accent);
    }
    final deep = _deepenAccent(accent);
    return _HubGlassCard(
      title: '喂养记录分析',
      logoUrl: careFeature?.logo ?? '',
      accent: deep,
      showChevron: unlocked && elig.isQualified,
      onTap: onCardTap,
      blurb: _FeedingAnalysisBlurb(accent: deep),
      entitlementCopy: entitlementCopy,
      metaLines: const [],
      body: body,
    );
  }
}

/// Hub 成长卡：开通门闸 / 已开通进子页。
class _HubGrowthCard extends ConsumerWidget {
  const _HubGrowthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    final vipExpire =
        ref.watch(vipStatusProvider).valueOrNull?.expireAt ?? 0;
    final feature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdGrowthTrajectoryPredict);
    final unlocked =
        isFeatureEffectivelyUnlocked(item: feature, isVip: isVip);
    final accent = resolveFeatureColor(context, feature);

    VoidCallback onCardTap;
    String? entitlementCopy;
    late final Widget body;

    if (!unlocked) {
      onCardTap = () => unawaited(
            openGrowthTrajectoryInviteUnlockDialog(
              context: context,
              ref: ref,
              feature: feature,
            ),
          );
      body = _hubMuted(context, '点击开通，结合宝宝近况定制未来 7 天成长提示', accent);
    } else {
      entitlementCopy = featureHubEntitlementRemainingCopy(
        item: feature,
        isVip: isVip,
        vipExpireAt: vipExpire,
      );
      onCardTap = () => context.push('/prediction/ai-analysis/growth');
      body = _hubMuted(context, '点击进入成长轨迹预测', accent);
    }

    return _HubGlassCard(
      title: '成长轨迹预测',
      logoUrl: feature?.logo ?? '',
      accent: accent,
      showChevron: unlocked,
      onTap: onCardTap,
      blurb: _GrowthTrajectoryBlurb(accent: accent),
      entitlementCopy: entitlementCopy,
      metaLines: const [],
      body: body,
    );
  }
}

class _HubGlassCard extends StatelessWidget {
  const _HubGlassCard({
    required this.title,
    required this.blurb,
    required this.body,
    required this.metaLines,
    required this.accent,
    this.entitlementCopy,
    this.onTap,
    this.showChevron = false,
    this.logoUrl = '',
  });

  final String title;
  final Widget blurb;
  final Widget body;
  final Color accent;
  final List<String> metaLines;
  final String? entitlementCopy;
  final VoidCallback? onTap;
  final bool showChevron;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.divider(context)),
            gradient: AppColor.panelGlassGradient(context, accent: accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                child: Row(
                  children: [
                    FeatureLogo(
                      logoUrl: logoUrl,
                      size: 26,
                      accent: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    // 剩余时效：标题右侧小字。
                    if (entitlementCopy != null &&
                        entitlementCopy!.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        entitlementCopy!,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                    if (showChevron)
                      Icon(
                        Icons.chevron_right,
                        color: accent.withValues(alpha: 0.7),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: blurb,
              ),
              if (metaLines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in metaLines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: accent.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              body,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    // 可点玻璃卡（角标在样张组件内，不在整卡外侧）。
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

Widget _hubMuted(BuildContext context, String text, Color accent) {
   final deep = _deepenAccent(accent);
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.35,
        color: deep,
      ),
    ),
  );
}

/// 样张正文 / 角标加深色，避免浅底上发灰。
Color _deepenAccent(Color accent) =>
    Color.lerp(accent, const Color(0xFF000000), 0.18)!;

/// 模拟样张块：角标在浅色底外侧左上 + 加深字色正文。
class _MockSamplePanel extends StatelessWidget {
  const _MockSamplePanel({
    required this.accent,
    required this.spans,
  });

  final Color accent;
  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    final deep = _deepenAccent(accent);
    final base = TextStyle(
      fontSize: 11,
      height: 1.35,
      color: deep,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 角标：贴样张面板外侧左上（非整卡外）。
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            '模拟内容 · 你可以得到这样的效果',
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: deep,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text.rich(
              TextSpan(style: base, children: spans),
            ),
          ),
        ),
      ],
    );
  }
}

/// 喂养模拟样张：浅功能色底 + 关键字加粗。
class _FeedingAnalysisBlurb extends StatelessWidget {
  const _FeedingAnalysisBlurb({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final deep = _deepenAccent(accent);
    final bold = TextStyle(
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w800,
      color: deep,
    );
    return _MockSamplePanel(
      accent: accent,
      spans: [
        const TextSpan(text: '🍼 近2日夜醒偏多，今日留意'),
        TextSpan(text: '喂养间隔', style: bold),
        const TextSpan(text: '与精神状态✨'),
      ],
    );
  }
}

/// 成长模拟样张：浅功能色底 + 关键字加粗。
class _GrowthTrajectoryBlurb extends StatelessWidget {
  const _GrowthTrajectoryBlurb({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final deep = _deepenAccent(accent);
    final bold = TextStyle(
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w800,
      color: deep,
    );
    return _MockSamplePanel(
      accent: accent,
      spans: [
        const TextSpan(text: '📈 未来7天或迎'),
        TextSpan(text: '身高冲刺', style: bold),
        const TextSpan(text: '，注意补钙与户外☀️'),
      ],
    );
  }
}

/// 合格未开通：开通引导文案持续心跳缩放。
class _UnlockHeartbeatPrompt extends StatefulWidget {
  const _UnlockHeartbeatPrompt({required this.accent});

  final Color accent;

  @override
  State<_UnlockHeartbeatPrompt> createState() => _UnlockHeartbeatPromptState();
}

class _UnlockHeartbeatPromptState extends State<_UnlockHeartbeatPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Text(
          '喂养记录已达标，点击开通智能分析',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: widget.accent,
          ),
        ),
      ),
    );
  }
}
