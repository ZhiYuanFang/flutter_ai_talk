import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/home_pager.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../providers/toast_bus.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'feature_unlock/invite_code_dialog.dart';
import 'widgets/app_toast.dart';
import 'widgets/feeding_eligibility_progress_text.dart';

/// 合格未开通：邀请码弹框；空码进开通中心；有码兑 care-alert。
Future<void> _openCareAlertInviteUnlockDialog({
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

/// AI 分析页：喂养记录分析（值得留意）+ 成长轨迹浅占位。
class AiAnalysisScreen extends ConsumerStatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // 进页：资格 + catalog + 今日已刷标记；不自动拉 daily。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(careAlertEligibilityStateProvider.notifier).ensureLoaded(),
      );
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
      unawaited(
        ref
            .read(predictionCareAlertStateProvider.notifier)
            .hydrateManualRefreshFlag(),
      );
    });
  }

  Future<void> _onTapAnalyze() async {
    final ok = await ref
        .read(predictionCareAlertStateProvider.notifier)
        .refreshDailyManual();
    if (!mounted) return;
    if (ok) {
      ref.showApiToast(
        '今日值得留意刷新成功，请明日再来',
        tone: AppToastTone.success,
      );
    } else {
      ref.showApiToast('分析失败，请稍后重试', tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shell = tokens?.shellColor ?? Theme.of(context).colorScheme.surface;
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;

    return Scaffold(
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
        children: [
          _FeedingAnalysisCard(onTapAnalyze: _onTapAnalyze),
          const SizedBox(height: 14),
          const _GrowthTrajectoryPlaceholder(),
        ],
      ),
    );
  }
}

/// 喂养记录分析：门闸 / 列表 / 手动 AI智能分析。
class _FeedingAnalysisCard extends ConsumerWidget {
  const _FeedingAnalysisCard({required this.onTapAnalyze});

  final Future<void> Function() onTapAnalyze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elig = ref.watch(careAlertEligibilityStateProvider);
    final careState = ref.watch(predictionCareAlertStateProvider);
    final items = ref.watch(predictionCareAlertProvider);
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    final careFeature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdCareAlertSmartRemind);
    final unlocked =
        isFeatureEffectivelyUnlocked(item: careFeature, isVip: isVip);
    final onGlass = AppColor.textOnPanelGlass(context);

    Widget body;
    Widget? trailingCta;

    if (!elig.isQualified) {
      if (elig.loading) {
        body = _mutedText(context, '正在校验喂养记录…');
      } else if (elig.failed) {
        body = InkWell(
          onTap: () => unawaited(
            ref
                .read(careAlertEligibilityStateProvider.notifier)
                .ensureLoaded(force: true),
          ),
          borderRadius: BorderRadius.circular(12),
          child: _mutedText(context, '资格校验失败，点击重试'),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: FeedingEligibilityProgressText(
              eligibility: elig.data!,
              kind: FeedingEligibilityProgressKind.careAlert,
              textAlign: TextAlign.start,
              numberScale: 1.65,
            ),
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
          child: _mutedText(context, '需累计有效喂养日以激活值得留意'),
        );
      }
    } else if (!unlocked) {
      body = InkWell(
        onTap: () => unawaited(
          _openCareAlertInviteUnlockDialog(
            context: context,
            ref: ref,
            careFeature: careFeature,
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: const _UnlockHeartbeatPrompt(),
      );
    } else if (careState.loading) {
      body = _mutedText(context, '正在思考中');
    } else {
      // 已开通：列表 + 未日限时 CTA
      if (!careState.manualRefreshSucceededToday) {
        trailingCta = _AiAnalyzeButton(onTap: onTapAnalyze);
      }
      if (items.isEmpty) {
        body = _mutedText(
          context,
          careState.manualRefreshSucceededToday
              ? '今日暂无值得留意事项'
              : '点击「AI智能分析」生成今日值得留意',
        );
      } else {
        body = Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: AppColor.divider(context)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  items[i].summaryLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: onGlass,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColor.textOnPanelGlassMuted(context),
                ),
                onTap: () =>
                    context.push('/prediction/alert', extra: items[i]),
              ),
            ],
          ],
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.divider(context)),
            gradient: AppColor.panelGlassGradient(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '喂养记录分析',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: onGlass,
                        ),
                      ),
                    ),
                    if (trailingCta != null) trailingCta,
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _FeedingAnalysisBlurb(),
              ),
              const SizedBox(height: 4),
              body,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mutedText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: AppColor.textOnPanelGlass(context).withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

/// 折中说明：近两日喂养 × 月龄 × 性别 → 今日留意；小字 + 圆角底。
class _FeedingAnalysisBlurb extends StatelessWidget {
  const _FeedingAnalysisBlurb();

  static const _copy =
      '根据近两日喂养记录，结合宝宝月龄与性别，智能分析今日值得留意之处。';

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
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
            color: onGlass.withValues(alpha: 0.68),
          ),
        ),
      ),
    );
  }
}

/// 合格未开通：开通引导文案持续心跳缩放（节奏对齐预测页 logo）。
class _UnlockHeartbeatPrompt extends StatefulWidget {
  const _UnlockHeartbeatPrompt();

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
    // 文案振幅略收，避免整行晃得过狠。
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
    final primary = AppColor.primary(context);
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
            color: primary,
          ),
        ),
      ),
    );
  }
}

class _AiAnalyzeButton extends StatelessWidget {
  const _AiAnalyzeButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => unawaited(onTap()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'AI智能分析',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 成长轨迹：浅占位，无 HTTP。
class _GrowthTrajectoryPlaceholder extends StatelessWidget {
  const _GrowthTrajectoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.divider(context)),
            gradient: AppColor.panelGlassGradient(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '成长轨迹预测',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onGlass,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '即将上线：通过简短问答了解宝宝近况，预测接下来一周可能的成长变化与注意事项。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: onGlass.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
