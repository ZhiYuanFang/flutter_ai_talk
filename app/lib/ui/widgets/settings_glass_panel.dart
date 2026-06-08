import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_visual_tokens.dart';

/// 设置中心同款玻璃拟态面板，供设置页与反馈页复用。
class SettingsGlassPanel extends StatelessWidget {
  const SettingsGlassPanel({
    super.key,
    required this.child,
    this.contentPadding,
  });

  final Widget child;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = visualTokensOf(context);
    final isDark = tokens?.isDarkShell ?? (theme.brightness == Brightness.dark);

    final base = tokens?.surfaceColor ?? scheme.surface;
    final top = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.06 : 0.20),
      base,
    );
    final bottom = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.16 : 0.10),
      base,
    );

    final borderColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
      scheme.outline.withValues(alpha: isDark ? 0.10 : 0.08),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [top, bottom],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: contentPadding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: child,
          ),
        ),
      ),
    );
  }
}
