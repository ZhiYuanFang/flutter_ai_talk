import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';

import '../../data/event_branding.dart';
import '../../data/event_definition.dart';
import '../../data/event_next_predictor.dart';
import '../../data/home_next_predict_prompt.dart';
import '../../providers/event_catalog_notifier.dart';
import '../../providers/smart_prediction_provider.dart';
import '../../theme/app_color.dart';
import '../../theme/app_visual_tokens.dart';
import '../event_logo.dart';

/// 喂养页历史与事件按钮之间：最近预测玻璃卡（无预测时不渲染）。
///
/// 作为页面 Column 固有高度子项占位，不叠在历史 [Expanded] 上；
/// 条带先铺 shell 底，避免半透玻璃看起来像盖住列表。
/// 占位高度变化时通知 [onChromeHeightChanged]，供历史跟底重锚。
class HomeNextPredictGlassCard extends ConsumerStatefulWidget {
  const HomeNextPredictGlassCard({
    super.key,
    required this.onCta,
    this.onChromeHeightChanged,
  });

  /// 仅 CTA 触发；[state] 供调用方决定直开 vs 强制 sheet。
  final Future<void> Function({
    required EventDefinition event,
    required EventNextPrediction prediction,
    required HomeNextPredictPromptState state,
  }) onCta;

  /// 卡占位高度相对上一帧变化（含 0↔非 0）时回调。
  final VoidCallback? onChromeHeightChanged;

  @override
  ConsumerState<HomeNextPredictGlassCard> createState() =>
      _HomeNextPredictGlassCardState();
}

class _HomeNextPredictGlassCardState
    extends ConsumerState<HomeNextPredictGlassCard> {
  static const double _logoSize = 36;
  static const double _radius = 16;
  static const double _blurSigma = 14;

  double _lastHeight = 0;

  void _reportHeightIfChanged() {
    final h = context.size?.height ?? 0;
    if ((h - _lastHeight).abs() < 0.5) return;
    _lastHeight = h;
    widget.onChromeHeightChanged?.call();
  }

  void _scheduleHeightReport() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reportHeightIfChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipAsync = ref.watch(homePredictionTipProvider);
    // refresh/reload 时 asData 为空会卸卡闪视口；valueOrNull 保留上一帧 tip
    final tip = tipAsync.valueOrNull;
    if (tip == null) {
      _scheduleHeightReport();
      return const SizedBox.shrink();
    }

    final now =
        ref.watch(predictionClockProvider).asData?.value ?? DateTime.now();
    final catalog = ref.watch(eventCatalogProvider).items;
    final definition = lookupEventById(catalog, tip.eventId);
    // 无目录项时仍可用预测上的名/色，但 CTA 需要可提交的 EventDefinition
    if (definition == null || !definition.hasValidEventType) {
      _scheduleHeightReport();
      return const SizedBox.shrink();
    }

    final state = homeNextPredictPromptState(tip.nextAt, now);
    final body = homeNextPredictPromptBody(
      state: state,
      eventName: tip.eventName,
    );
    final timeLabel = homeNextPredictPromptTimeLabel(tip.nextAt, now);
    final cta = homeNextPredictPromptCtaLabel(
      state: state,
      eventType: definition.parsedEventType,
    );
    final accent = _accentFor(context, tip, definition);
    final onGlass = AppColor.textOnPanelGlass(context);
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg =
        tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;

    _scheduleHeightReport();

    // shell 底色条带占位 → 其上再铺 panelGlass，不透出历史列表
    return ColoredBox(
      color: shellBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: AppColor.divider(context)),
                gradient: AppColor.panelGlassGradient(context, accent: accent),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    EventLogo(definition: definition, size: _logoSize),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: accent.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => widget.onCta(
                        event: definition,
                        prediction: tip,
                        state: state,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: _onAccent(accent, onGlass),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        cta,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _accentFor(
    BuildContext context,
    EventNextPrediction tip,
    EventDefinition definition,
  ) {
    final fromPred = tip.colorHex.trim();
    if (fromPred.isNotEmpty) {
      final parsed = _parseHex(fromPred);
      if (parsed != null) return parsed;
    }
    return resolveEventColor(context, definition);
  }

  static Color? _parseHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  /// 强调色上的按钮字：够暗用浅字，否则用 panelGlass 正文色。
  static Color _onAccent(Color accent, Color fallbackOnGlass) {
    final luminance = accent.computeLuminance();
    if (luminance < 0.45) return Colors.white;
    return fallbackOnGlass;
  }
}
