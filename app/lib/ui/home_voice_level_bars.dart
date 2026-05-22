import 'package:flutter/material.dart';

import '../audio/voice_level_smoother.dart';

/// 主页按住聆听时的多柱响度指示器。
class HomeVoiceLevelBars extends StatelessWidget {
  const HomeVoiceLevelBars({
    super.key,
    required this.level,
    required this.cancelled,
    this.maxBarHeight = 40,
  });

  final double level;
  final bool cancelled;
  final double maxBarHeight;

  static const _minBarHeight = 4.0;
  static const _barWidth = 5.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lo = cancelled
        ? scheme.error.withValues(alpha: 0.45)
        : scheme.primary.withValues(alpha: 0.35);
    final hi = cancelled
        ? scheme.error.withValues(alpha: 0.9)
        : scheme.primary.withValues(alpha: 0.95);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < kHomeVoiceLevelBarWobble.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          _LevelBar(
            width: _barWidth,
            height: _minBarHeight +
                (maxBarHeight - _minBarHeight) *
                    (level * kHomeVoiceLevelBarWobble[i]).clamp(0.0, 1.0),
            color: Color.lerp(lo, hi, kHomeVoiceLevelBarWobble[i]) ?? lo,
          ),
        ],
      ],
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
