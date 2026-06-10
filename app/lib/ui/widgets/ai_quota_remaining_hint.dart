import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ai_quota_provider.dart';

/// AI 入口旁展示本月剩余次数；无数据时不占位。
class AiQuotaRemainingHint extends ConsumerWidget {
  const AiQuotaRemainingHint({
    super.key,
    required this.feature,
    this.padding = EdgeInsets.zero,
  });

  final AiQuotaRemainingHintFeature feature;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aiQuotaStatusProvider);
    return async.when(
      data: (status) {
        if (status == null) return const SizedBox.shrink();
        final snap = feature == AiQuotaRemainingHintFeature.polish ? status.polish : status.voiceAi;
        if (snap.limit <= 0) return const SizedBox.shrink();
        final label = feature == AiQuotaRemainingHintFeature.polish
            ? '本月润笔剩余 ${snap.remaining} 次'
            : '本月 AI 对话剩余 ${snap.remaining} 次';
        final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
        return Padding(
          padding: padding,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, height: 1.3, color: color),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

enum AiQuotaRemainingHintFeature { polish, voiceAi }
