import 'package:flutter/material.dart';

/// 原力档位图标：[0,500) 不渲染；与 go `ForceTierFromValue` 对齐。
class UcgForceTierIcon extends StatelessWidget {
  const UcgForceTierIcon({
    super.key,
    required this.forceValue,
    this.forceTier,
    this.size = 14,
    this.onTap,
  });

  final int forceValue;
  final String? forceTier;
  final double size;
  final VoidCallback? onTap;

  /// 档位阈值（升序）：青铜 500 → 钻石 2500。
  static const tierThresholds = [500, 1000, 1500, 2000, 2500];

  static const tierKeys = ['bronze', 'silver', 'gold', 'platinum', 'diamond'];

  static const tierDisplayNames = ['青铜', '白银', '黄金', '铂金', '钻石'];

  static String? tierFromValue(int value, {String? apiTier}) {
    final fromApi = apiTier?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    if (value < 500) return null;
    if (value < 1000) return 'bronze';
    const tiers = ['silver', 'gold', 'platinum', 'diamond'];
    final idx = (value - 1000) ~/ 500;
    return tiers[idx.clamp(0, tiers.length - 1)];
  }

  /// 下一档阈值；已达最高档返回 null。
  static int? nextTierThreshold(int value) {
    for (final t in tierThresholds) {
      if (value < t) return t;
    }
    return null;
  }

  /// 距下一档还差多少分；已达最高档返回 null。
  static int? pointsToNextTier(int value) {
    final next = nextTierThreshold(value);
    if (next == null) return null;
    return next - value;
  }

  /// 档位中文名。
  static String tierLabel(String? tierKey) {
    if (tierKey == null || tierKey.isEmpty) return '暂无档位';
    final idx = tierKeys.indexOf(tierKey);
    if (idx >= 0) return tierDisplayNames[idx];
    return tierKey;
  }

  /// 下一档中文名。
  static String? nextTierLabel(int value) {
    final next = nextTierThreshold(value);
    if (next == null) return null;
    final idx = tierThresholds.indexOf(next);
    if (idx < 0) return null;
    return tierDisplayNames[idx];
  }

  @override
  Widget build(BuildContext context) {
    final tier = tierFromValue(forceValue, apiTier: forceTier);
    if (tier == null && onTap == null) return const SizedBox.shrink();

    final (icon, color) = switch (tier) {
      'bronze' => (Icons.bolt_rounded, const Color(0xFFCD7F32)),
      'silver' => (Icons.bolt_rounded, const Color(0xFF9E9E9E)),
      'gold' => (Icons.bolt_rounded, const Color(0xFFFFB300)),
      'platinum' => (Icons.bolt_rounded, const Color(0xFF78909C)),
      'diamond' => (Icons.diamond_rounded, const Color(0xFF26C6DA)),
      _ => (Icons.bolt_rounded, Theme.of(context).colorScheme.primary),
    };

    final iconWidget = Icon(icon, size: size, color: color);
    if (onTap == null) {
      if (tier == null) return const SizedBox.shrink();
      return iconWidget;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: tier == null
          ? Icon(Icons.bolt_outlined, size: size, color: color.withValues(alpha: 0.55))
          : iconWidget,
    );
  }
}
