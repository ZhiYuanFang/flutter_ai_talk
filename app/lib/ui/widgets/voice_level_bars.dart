import 'package:flutter/material.dart';

import '../../audio/voice_level_smoother.dart';

/// 可复用语音能量柱：由调用方传入 accent，不绑定首页 primary。
class VoiceLevelBars extends StatelessWidget {
  const VoiceLevelBars({
    super.key,
    required this.level,
    required this.accent,
    required this.cancelled,
    this.maxBarHeight = 40,
  });

  /// 归一化响度 0..1
  final double level;
  /// 聆听态柱条主色（取消态改用 error）
  final Color accent;
  final bool cancelled;
  final double maxBarHeight;

  static const _minBarHeight = 4.0;
  static const _barWidth = 5.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 取消：error 系；正常：accent 浅→深
    final lo = cancelled
        ? scheme.error.withValues(alpha: 0.45)
        : accent.withValues(alpha: 0.35);
    final hi = cancelled
        ? scheme.error.withValues(alpha: 0.9)
        : accent.withValues(alpha: 0.95);

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
