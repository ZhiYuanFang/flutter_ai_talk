import 'package:flutter/material.dart';

/// 原力档位图标：[0,500) 不渲染；与 go `ForceTierFromValue` 对齐。
class UcgForceTierIcon extends StatelessWidget {
  const UcgForceTierIcon({
    super.key,
    required this.forceValue,
    this.forceTier,
    this.size = 14,
  });

  final int forceValue;
  final String? forceTier;
  final double size;

  static String? tierFromValue(int value, {String? apiTier}) {
    final fromApi = apiTier?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    if (value < 500) return null;
    if (value < 1000) return 'bronze';
    const tiers = ['silver', 'gold', 'platinum', 'diamond'];
    final idx = (value - 1000) ~/ 500;
    return tiers[idx.clamp(0, tiers.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final tier = tierFromValue(forceValue, apiTier: forceTier);
    if (tier == null) return const SizedBox.shrink();

    final (icon, color) = switch (tier) {
      'bronze' => (Icons.bolt_rounded, const Color(0xFFCD7F32)),
      'silver' => (Icons.bolt_rounded, const Color(0xFF9E9E9E)),
      'gold' => (Icons.bolt_rounded, const Color(0xFFFFB300)),
      'platinum' => (Icons.bolt_rounded, const Color(0xFF78909C)),
      'diamond' => (Icons.diamond_rounded, const Color(0xFF26C6DA)),
      _ => (Icons.bolt_rounded, Theme.of(context).colorScheme.primary),
    };

    return Icon(icon, size: size, color: color);
  }
}
