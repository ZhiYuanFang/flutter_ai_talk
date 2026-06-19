import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_quota_models.dart';
import '../../providers/ai_quota_provider.dart';

/// AI 入口旁展示本月剩余次数；无数据时不占位。
class AiQuotaRemainingHint extends ConsumerWidget {
  const AiQuotaRemainingHint({
    super.key,
    required this.feature,
    this.padding = EdgeInsets.zero,
    this.glassStyle = false,
  });

  final AiQuotaRemainingHintFeature feature;
  final EdgeInsetsGeometry padding;
  final bool glassStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (feature == AiQuotaRemainingHintFeature.polish) {
      final async = ref.watch(polishAiQuotaProvider);
      return async.when(
        data: (status) => _buildHint(context, status?.polish, feature),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    }
    final async = ref.watch(voiceAiQuotaProvider);
    return async.when(
      data: (status) {
        if (status == null) return const SizedBox.shrink();
        final snap = feature == AiQuotaRemainingHintFeature.clinicAi ? status.clinicAi : status.voiceAi;
        return _buildHint(context, snap, feature);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHint(BuildContext context, AiQuotaFeatureStatus? snap, AiQuotaRemainingHintFeature feature) {
    if (snap == null || snap.limit <= 0) return const SizedBox.shrink();
    final label = switch (feature) {
      AiQuotaRemainingHintFeature.polish => '本月润笔剩余 ${snap.remaining} 次',
      AiQuotaRemainingHintFeature.clinicAi => '本月胖宝诊疗剩余 ${snap.remaining} 次',
      AiQuotaRemainingHintFeature.voiceAi => '本月 AI 对话剩余 ${snap.remaining} 次',
    };
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final text = Text(
      label,
      style: TextStyle(fontSize: 12, height: 1.3, color: color),
    );
    if (!glassStyle) {
      return Padding(padding: padding, child: text);
    }
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: text,
            ),
          ),
        ),
      ),
    );
  }
}

enum AiQuotaRemainingHintFeature { polish, voiceAi, clinicAi }
