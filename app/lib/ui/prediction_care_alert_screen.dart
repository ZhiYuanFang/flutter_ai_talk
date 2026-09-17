import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../data/client_usage_events.dart';
import '../data/feature_unlock_models.dart';
import '../data/prediction_care_alert.dart';
import '../providers/client_usage_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../theme/app_visual_tokens.dart';

/// 护理留意详情：展示该事件全部原因（功能色；忽略/追问暂隐）。
class PredictionCareAlertScreen extends ConsumerWidget {
  const PredictionCareAlertScreen({super.key, required this.item});

  final CareAlertEventItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final shell = tokens?.shellColor ?? scheme.surface;
    final onShell = tokens?.onShell ?? scheme.onSurface;
    // 强调色跟喂养记录分析（care-alert）功能色
    final careFeature = ref
        .watch(featureCatalogStateProvider)
        .byId(kFeatureIdCareAlertSmartRemind);
    final accent = resolveFeatureColor(context, careFeature);
    final deep = Color.lerp(accent, const Color(0xFF000000), 0.18)!;

    return ClientUsageShowOnce(
      event: ClientUsageEvents.careAlertShow,
      child: Scaffold(
        backgroundColor: shell,
        appBar: AppBar(
          backgroundColor: shell,
          foregroundColor: onShell,
          title: Text(
            '值得留意',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _GlassPanel(
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.eventName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: deep,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.summaryLine,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '这是相对你宝宝近期记录与月龄期望的对照提示，不是医疗诊断。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: onShell.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            for (final reason in item.reasons) ...[
              const SizedBox(height: 14),
              _GlassPanel(
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason.typeLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: deep,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _kv(onShell, '类型', reason.typeLabel),
                    if (reason.ageMonths != null)
                      _kv(onShell, '月龄', '${reason.ageMonths} 个月')
                    else
                      _kv(onShell, '月龄', '未使用（生日不可用）'),
                    for (final line in reason.detailLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MarkdownWidget(
                          data: line,
                          shrinkWrap: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(Color onShell, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 13,
                color: onShell.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onShell.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.12),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
