import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../providers/cash_vip_provider.dart';
import '../providers/client_usage_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../providers/growth_trajectory_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'ai_analysis_unlock.dart';
import 'widgets/app_toast.dart';
import 'widgets/clinic_answer_body.dart';
import 'widgets/feature_logo.dart';

/// 成长轨迹工作台：无卡片；正文下 CTA；功能色渐变底。
class GrowthTrajectoryScreen extends ConsumerStatefulWidget {
  const GrowthTrajectoryScreen({super.key});

  @override
  ConsumerState<GrowthTrajectoryScreen> createState() =>
      _GrowthTrajectoryScreenState();
}

class _GrowthTrajectoryScreenState
    extends ConsumerState<GrowthTrajectoryScreen> {
  final _freeTextController = TextEditingController();
  /// choice 题：展开「手动输入」时隐藏双按钮
  bool _choiceManualMode = false;

  /// choice 选项：圆角矩形
  static final _choiceButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
      final isVip = ref.read(vipStatusProvider).valueOrNull?.isVip == true;
      final feature = ref
          .read(featureCatalogStateProvider)
          .byId(kFeatureIdGrowthTrajectoryPredict);
      if (isFeatureEffectivelyUnlocked(item: feature, isVip: isVip) ||
          canAccessFeatureDetail(item: feature, isVip: isVip)) {
        unawaited(
          ref.read(growthTrajectoryStateProvider.notifier).ensureLatest(),
        );
      }
    });
  }

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  void _collapseChoiceManual() {
    if (!_choiceManualMode && _freeTextController.text.isEmpty) return;
    _choiceManualMode = false;
    _freeTextController.clear();
  }

  Future<void> _toastIfErr(String? err) async {
    if (!mounted || err == null || err.isEmpty) return;
    showAppToast(err, tone: AppToastTone.error);
  }

  Future<void> _onPredict({required bool restart}) async {
    final err = await ref
        .read(growthTrajectoryStateProvider.notifier)
        .startPredict(restart: restart);
    await _toastIfErr(err);
    // 试用首次成功后服务端 claim，刷新目录。
    unawaited(ref.read(featureCatalogStateProvider.notifier).refresh());
  }

  Future<void> _onChoice(String value) async {
    final q = ref.read(growthTrajectoryStateProvider).question;
    if (q == null) return;
    final err = await ref
        .read(growthTrajectoryStateProvider.notifier)
        .submitAnswer(questionId: q.id, value: value);
    await _toastIfErr(err);
  }

  Future<void> _onSubmitFreeText() async {
    final q = ref.read(growthTrajectoryStateProvider).question;
    if (q == null) return;
    final text = _freeTextController.text;
    if (text.trim().isEmpty) {
      showAppToast('请填写后再提交', tone: AppToastTone.error);
      return;
    }
    final err = await ref
        .read(growthTrajectoryStateProvider.notifier)
        .submitAnswer(questionId: q.id, value: text);
    if (err == null) {
      setState(_collapseChoiceManual);
    }
    await _toastIfErr(err);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final scheme = Theme.of(context).colorScheme;
    final gt = ref.watch(growthTrajectoryStateProvider);
    final isVip = ref.watch(vipStatusProvider).valueOrNull?.isVip == true;
    final feature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdGrowthTrajectoryPredict);
    final canUse = canAccessFeatureDetail(item: feature, isVip: isVip);
    final accent = resolveFeatureColor(context, feature);

    // 页底混入功能主色（对齐喂养 sheet 玻璃 tint）
    final bgStart = AppColor.pageBg(context);
    final bgEnd = Color.lerp(bgStart, accent, 0.28) ?? scheme.surface;

    ref.listen(growthTrajectoryStateProvider, (prev, next) {
      final prevId = prev?.question?.id;
      final nextId = next.question?.id;
      if (prevId == nextId) return;
      if (!_choiceManualMode && _freeTextController.text.isEmpty) return;
      setState(_collapseChoiceManual);
    });

    ref.listen(featureCatalogStateProvider, (prev, next) {
      final was = isFeatureEffectivelyUnlocked(
        item: prev?.byId(kFeatureIdGrowthTrajectoryPredict),
        isVip: isVip,
      );
      final now = isFeatureEffectivelyUnlocked(
        item: next.byId(kFeatureIdGrowthTrajectoryPredict),
        isVip: isVip,
      );
      if (!was && now) {
        unawaited(
          ref
              .read(growthTrajectoryStateProvider.notifier)
              .ensureLatest(force: true),
        );
      }
    });
    ref.listen(vipStatusProvider, (prev, next) {
      final wasVip = prev?.valueOrNull?.isVip == true;
      final nowVip = next.valueOrNull?.isVip == true;
      if (!wasVip && nowVip) {
        unawaited(
          ref
              .read(growthTrajectoryStateProvider.notifier)
              .ensureLatest(force: true),
        );
      }
    });

    // 主 CTA 在正文下（对齐喂养工作台）；流式/提问中隐藏
    Widget? bottomCta;
    final canShowCta = gt.phase != GrowthTrajectoryPhase.streaming &&
        gt.phase != GrowthTrajectoryPhase.asking &&
        gt.phase != GrowthTrajectoryPhase.loadingLatest;
    if (canShowCta) {
      if (!canUse) {
        bottomCta = _GrowthBodyCta(
          label: '轨迹预测',
          accent: accent,
          onTap: () => openGrowthTrajectoryInviteUnlockDialog(
            context: context,
            ref: ref,
            feature: feature,
          ),
        );
      } else if (gt.hasResult) {
        bottomCta = _GrowthBodyCta(
          label: '重新预测',
          accent: accent,
          usageCopy: gt.usageCopy,
          onTap: () => _onPredict(restart: true),
        );
      } else {
        bottomCta = _GrowthBodyCta(
          label: '轨迹预测',
          accent: accent,
          usageCopy: gt.usageCopy,
          onTap: () => _onPredict(restart: false),
        );
      }
    }

    // 页内文案跟成长功能色（浅底加深）。
    final deep = _gtDeepenAccent(accent);
    final muted = deep.withValues(alpha: 0.85);
    final hint = accent.withValues(alpha: 0.55);

    Widget body;
    if (!canUse) {
      body = _gtMuted(
        context,
        '点击「轨迹预测」，结合宝宝近况定制未来 7 天成长提示',
        muted,
      );
    } else if (gt.phase == GrowthTrajectoryPhase.loadingLatest) {
      body = _gtMuted(context, '正在加载历史轨迹…', muted);
    } else if (gt.showThinking || gt.phase == GrowthTrajectoryPhase.streaming) {
      body = _ThinkingPane(
        text: gt.thinking.isEmpty ? '正在思考…' : gt.thinking,
        color: deep.withValues(alpha: 0.9),
      );
    } else if (gt.phase == GrowthTrajectoryPhase.asking && gt.question != null) {
      final q = gt.question!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.prompt,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: deep,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (q.isChoice && !_choiceManualMode) ...[
            // 纵向全宽，便于长文案
            for (final c in q.twoChoices) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: _choiceButtonShape,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => unawaited(_onChoice(c)),
                  child: Text(c, textAlign: TextAlign.center),
                ),
              ),
              if (c != q.twoChoices.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: hint,
                ),
                onPressed: () => setState(() => _choiceManualMode = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_alt_outlined, size: 14, color: hint),
                    const SizedBox(width: 4),
                    Text(
                      '手动输入',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: hint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (q.isChoice && _choiceManualMode) ...[
            TextField(
              controller: _freeTextController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '请输入补充说明',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(_collapseChoiceManual),
                  child: const Text('收起'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => unawaited(_onSubmitFreeText()),
                  child: const Text('提交'),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _freeTextController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '请输入补充说明',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => unawaited(_onSubmitFreeText()),
                child: const Text('提交'),
              ),
            ),
          ],
        ],
      );
    } else if (gt.hasResult) {
      body = ClinicAnswerBody(
        text: gt.resultMarkdown,
        streaming: false,
        scrollable: false,
        selectable: true,
      );
    } else {
      body = _gtMuted(
        context,
        '点击「轨迹预测」，结合宝宝近况定制未来 7 天成长提示',
        muted,
      );
    }

    return ClientUsageShowOnce(
      event: ClientUsageEvents.growthShow,
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
              logoUrl: feature?.logo ?? '',
              size: 26,
              accent: accent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '成长轨迹',
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
              _GrowthBlurb(accent: accent),
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

  Widget _gtMuted(BuildContext context, String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, height: 1.35, color: color),
    );
  }
}

/// 浅底正文加深（对齐 Hub / 喂养工作台）。
Color _gtDeepenAccent(Color accent) =>
    Color.lerp(accent, const Color(0xFF000000), 0.18)!;

class _GrowthBlurb extends StatelessWidget {
  const _GrowthBlurb({required this.accent});

  final Color accent;

  static const _copy =
      '通过宝宝近况，结合月龄与近期喂养，预测接下来 7 天可能的成长变化与注意事项。';

  @override
  Widget build(BuildContext context) {
    final deep = _gtDeepenAccent(accent);
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

/// 正文下方居中：预测按钮 + 可选用量小字。
class _GrowthBodyCta extends StatelessWidget {
  const _GrowthBodyCta({
    required this.label,
    required this.onTap,
    required this.accent,
    this.usageCopy,
  });

  final String label;
  final Future<void> Function() onTap;
  final Color accent;
  final String? usageCopy;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => unawaited(onTap()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ),
    );
    final usage = usageCopy?.trim();
    if (usage == null || usage.isEmpty) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 6),
        Text(
          usage,
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

class _ThinkingPane extends StatelessWidget {
  const _ThinkingPane({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.4;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: TextStyle(fontSize: 13, height: 1.4, color: color),
        ),
      ),
    );
  }
}
