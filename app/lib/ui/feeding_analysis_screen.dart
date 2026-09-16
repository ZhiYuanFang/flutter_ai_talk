import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/client_usage_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/home_pager.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../providers/toast_bus.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'ai_analysis_unlock.dart';
import 'widgets/app_toast.dart';
import 'widgets/feature_logo.dart';
import 'widgets/feeding_eligibility_progress_text.dart';

/// 喂养记录分析工作台：无卡片；AppBar CTA；主题色渐变底（对齐成长轨迹）。
class FeedingAnalysisScreen extends ConsumerStatefulWidget {
  const FeedingAnalysisScreen({super.key});

  @override
  ConsumerState<FeedingAnalysisScreen> createState() =>
      _FeedingAnalysisScreenState();
}

class _FeedingAnalysisScreenState extends ConsumerState<FeedingAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // 进页不自动 daily；仅补资格/目录以便门禁。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(careAlertEligibilityStateProvider.notifier).ensureLoaded(),
      );
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
      // 可访问时拉 latest 缓存（不 force，不扣次）。
      unawaited(_loadLatestIfAccessible());
    });
  }

  Future<void> _loadLatestIfAccessible() async {
    final isVip = ref.read(vipStatusProvider).valueOrNull?.isVip == true;
    final careFeature = ref
        .read(featureCatalogStateProvider)
        .byId(kFeatureIdCareAlertSmartRemind);
    if (!canAccessFeatureDetail(item: careFeature, isVip: isVip)) return;
    final elig = ref.read(careAlertEligibilityStateProvider);
    if (!elig.isQualified && !elig.loading) {
      await ref.read(careAlertEligibilityStateProvider.notifier).ensureLoaded();
    }
    if (!ref.read(careAlertEligibilityStateProvider).isQualified) return;
    // 复用 provider：无 force 的 hydrate 走 repository force:false
    await ref.read(predictionCareAlertStateProvider.notifier).hydrateLatestOnly();
  }

  Future<void> _onTapAnalyze() async {
    final err = await ref
        .read(predictionCareAlertStateProvider.notifier)
        .refreshDailyManual();
    if (!mounted) return;
    if (err != null) {
      ref.showApiToast(err, tone: AppToastTone.error);
    }
    // 试用首次成功后服务端 claim，刷新目录同步 trial/unlocked。
    unawaited(ref.read(featureCatalogStateProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final scheme = Theme.of(context).colorScheme;
    final elig = ref.watch(careAlertEligibilityStateProvider);
    final careState = ref.watch(predictionCareAlertStateProvider);
    final items = ref.watch(predictionCareAlertProvider);
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    final careFeature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdCareAlertSmartRemind);
    final canUse = canAccessFeatureDetail(item: careFeature, isVip: isVip);
    final accent = resolveFeatureColor(context, careFeature);
    // 浅底 / 提示用加深 accent，对齐 Hub 可读策略。
    final deep = _deepenAccent(accent);

    // 页底混入功能主色（对齐成长工作台）。
    final bgStart = AppColor.pageBg(context);
    final bgEnd = Color.lerp(bgStart, accent, 0.28) ?? scheme.surface;

    Widget body;
    Widget? bottomCta;

    if (!elig.isQualified) {
      if (elig.loading) {
        body = _muted(context, '正在校验喂养记录…', deep);
      } else if (elig.failed) {
        body = InkWell(
          onTap: () => unawaited(
            ref
                .read(careAlertEligibilityStateProvider.notifier)
                .ensureLoaded(force: true),
          ),
          borderRadius: BorderRadius.circular(12),
          child: _muted(context, '资格校验失败，点击重试', deep),
        );
      } else if (elig.data != null) {
        body = InkWell(
          onTap: () {
            ref
                .read(homePagerRequestProvider.notifier)
                .requestPage(HomePagerPage.feeding);
            context.go('/home');
          },
          borderRadius: BorderRadius.circular(12),
          child: FeedingEligibilityProgressText(
            eligibility: elig.data!,
            kind: FeedingEligibilityProgressKind.careAlert,
            textAlign: TextAlign.start,
            numberScale: 1.65,
            accent: accent,
          ),
        );
      } else {
        body = InkWell(
          onTap: () {
            ref
                .read(homePagerRequestProvider.notifier)
                .requestPage(HomePagerPage.feeding);
            context.go('/home');
          },
          borderRadius: BorderRadius.circular(12),
          child: _muted(context, '需累计有效喂养日以激活值得留意', deep),
        );
      }
    } else if (!canUse) {
      body = InkWell(
        onTap: () => unawaited(
          openCareAlertInviteUnlockDialog(
            context: context,
            ref: ref,
            careFeature: careFeature,
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Text(
          '喂养记录已达标，点击开通智能分析',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: deep,
          ),
        ),
      );
    } else if (careState.loading) {
      body = _muted(context, '正在思考中', deep);
      // 分析中仍展示 CTA 区说明，便于用户感知入口。
      bottomCta = _FeedingBodyCta(
        accent: accent,
        onTap: null,
      );
    } else {
      // 合格且可使用：CTA 在正文下方居中；日限文案对齐用户日 5 次。
      bottomCta = _FeedingBodyCta(
        accent: accent,
        onTap: _onTapAnalyze,
      );
      if (items.isEmpty) {
        body = _muted(context, '点击下方「AI智能分析」生成今日值得留意', deep);
      } else {
        body = Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: AppColor.divider(context)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  items[i].summaryLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: deep,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: accent.withValues(alpha: 0.55),
                ),
                onTap: () =>
                    context.push('/prediction/alert', extra: items[i]),
              ),
            ],
          ],
        );
      }
    }

    return ClientUsageShowOnce(
      event: ClientUsageEvents.feedingAnalysisShow,
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onShell,
        title: Row(
          children: [
            FeatureLogo(
              logoUrl: careFeature?.logo ?? '',
              size: 26,
              accent: accent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '喂养记录分析',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _FeedingBlurb(accent: accent),
              const SizedBox(height: 12),
              body,
              if (bottomCta != null) ...[
                const SizedBox(height: 28),
                Center(child: bottomCta),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _muted(BuildContext context, String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, height: 1.35, color: color),
    );
  }
}

/// 浅底正文加深，避免高透明发灰（对齐 Hub）。
Color _deepenAccent(Color accent) =>
    Color.lerp(accent, const Color(0xFF000000), 0.18)!;

class _FeedingBlurb extends StatelessWidget {
  const _FeedingBlurb({required this.accent});

  final Color accent;

  static const _copy =
      '根据近两日喂养记录，结合宝宝月龄与性别，智能分析今日值得留意之处。';

  @override
  Widget build(BuildContext context) {
    final deep = _deepenAccent(accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.fieldFill(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          _copy,
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: deep,
          ),
        ),
      ),
    );
  }
}

/// 正文下方居中：AI智能分析 + 日限说明（用户每日最多 5 次）。
class _FeedingBodyCta extends StatelessWidget {
  const _FeedingBodyCta({
    required this.accent,
    required this.onTap,
  });

  final Future<void> Function()? onTap;
  final Color accent;

  static const _usageHint = '每个账号每日最多分析 5 次，每次重新生成';

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final button = Material(
      color: accent.withValues(alpha: enabled ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? () => unawaited(onTap!()) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'AI智能分析',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent.withValues(alpha: enabled ? 1 : 0.45),
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 6),
        Text(
          _usageHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            color: accent.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
