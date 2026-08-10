import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_branding.dart';
import '../../data/event_definition.dart';
import '../../data/event_next_predictor.dart';
import '../../home_widget/format_widget_relative_time.dart';
import '../../providers/event_catalog_notifier.dart';
import '../../providers/home_pager.dart';
import '../../providers/smart_prediction_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../event_logo.dart';

/// 喂养页顶部固定预测贴士：最近下一步 /「暂无预测」；点击进智能预测（无跳过）。
class HomePredictionTipBar extends ConsumerWidget {
  const HomePredictionTipBar({super.key});

  static const double _logoSize = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(homePredictionTipProvider);
    final now =
        ref.watch(predictionClockProvider).asData?.value ?? DateTime.now();
    final catalog = ref.watch(eventCatalogProvider).items;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final onShell = tokens?.onShell ?? scheme.onSurface;

    void openPrediction() {
      ref
          .read(homePagerRequestProvider.notifier)
          .requestPage(HomePagerPage.prediction);
    }

    return Material(
      color: (tokens?.shellColor ?? scheme.surface).withValues(alpha: 0.92),
      child: tipAsync.when(
        data: (tip) => _BarBody(
          tip: tip,
          definition: tip == null ? null : lookupEventById(catalog, tip.eventId),
          now: now,
          onShell: onShell,
          onOpenPrediction: openPrediction,
        ),
        loading: () => _BarBody(
          tip: null,
          definition: null,
          now: now,
          onShell: onShell,
          placeholderLoading: true,
          onOpenPrediction: openPrediction,
        ),
        error: (_, __) => _BarBody(
          tip: null,
          definition: null,
          now: now,
          onShell: onShell,
          onOpenPrediction: openPrediction,
        ),
      ),
    );
  }
}

class _BarBody extends StatelessWidget {
  const _BarBody({
    required this.tip,
    required this.definition,
    required this.now,
    required this.onShell,
    required this.onOpenPrediction,
    this.placeholderLoading = false,
  });

  final EventNextPrediction? tip;
  final EventDefinition? definition;
  final DateTime now;
  final Color onShell;
  final VoidCallback onOpenPrediction;
  final bool placeholderLoading;

  Color _eventAccent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hex = tip?.colorHex;
    if (hex == null || hex.isEmpty) return scheme.primary;
    final parsed = _parseHex(hex);
    return parsed ?? scheme.primary;
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

  @override
  Widget build(BuildContext context) {
    final hasTip = tip != null;
    final title = hasTip
        ? tip!.eventName
        : (placeholderLoading ? '预测加载中…' : '暂无预测');
    final subtitle = hasTip
        ? formatWidgetPredictSubtitle(
            tip!.nextAt,
            now,
            overdue: tip!.isOverdue(now),
          )
        : null;
    final accent = _eventAccent(context);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 52,
        child: InkWell(
          onTap: onOpenPrediction,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (hasTip) ...[
                  EventLogo(
                    definition: definition,
                    size: HomePredictionTipBar._logoSize,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onShell,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
