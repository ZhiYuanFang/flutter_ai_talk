import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_visual_tokens.dart';

/// 历史编辑 Sheet 玻璃拟态容器（磨砂 + 渐变 + 微光描边）。
class HistoryEditGlassPanel extends StatelessWidget {
  const HistoryEditGlassPanel({
    super.key,
    required this.child,
    this.onClose,
    this.eventAccent,
  });

  final Widget child;
  final VoidCallback? onClose;
  final Color? eventAccent;

  static const _radius = 22.0;
  static const _blurSigma = 20.0;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = tokens?.isDarkShell ?? (Theme.of(context).brightness == Brightness.dark);
    final accent = eventAccent ?? scheme.primary;

    final fillTop = isDark
        ? const Color(0xFF1A2428).withValues(alpha: 0.72)
        : const Color(0xFF2A3438).withValues(alpha: 0.78);
    final fillBottom = Color.lerp(
          fillTop,
          accent.withValues(alpha: isDark ? 0.22 : 0.18),
          0.55,
        ) ??
        fillTop;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.22),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [fillTop, fillBottom],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                  child: child,
                ),
                if (onClose != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close,
                        size: 22,
                        color: (tokens?.onShell ?? Colors.white).withValues(alpha: 0.92),
                      ),
                      tooltip: '关闭',
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

/// 玻璃编辑区内标签文字色。
Color historyEditGlassLabelColor(BuildContext context) {
  final tokens = Theme.of(context).extension<AppVisualTokens>();
  return (tokens?.onShell ?? Theme.of(context).colorScheme.onSurface)
      .withValues(alpha: 0.78);
}

/// 玻璃编辑区内主文字色。
Color historyEditGlassTextColor(BuildContext context) {
  final tokens = Theme.of(context).extension<AppVisualTokens>();
  return tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
}

InputDecoration historyEditGlassInputDecoration(
  BuildContext context, {
  required String labelText,
}) {
  final label = historyEditGlassLabelColor(context);
  final border = historyEditGlassFieldBorder(context);
  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: label, fontSize: 13),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
    ),
    border: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

OutlineInputBorder historyEditGlassFieldBorder(BuildContext context) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
  );
}

/// 玻璃质感可点击输入条容器。
class HistoryEditGlassTapField extends StatelessWidget {
  const HistoryEditGlassTapField({
    super.key,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.minHeight = 52,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }
}
