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
    this.contentPadding,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onClose;
  final Color? eventAccent;
  final EdgeInsets? contentPadding;
  final double? borderRadius;

  static const _radius = 22.0;
  static const _blurSigma = 20.0;

  /// 玻璃面板固定浅色前景（底为事件色暗色渐变，不随 shell [AppVisualTokens.onShell] 变暗）。
  static const Color glassTextColor = Color(0xFFF3F5F7);
  static const Color glassLabelColor = Color(0xFFE0E6EB);

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
    final radius = borderRadius ?? _radius;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
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
                  padding: contentPadding ?? const EdgeInsets.fromLTRB(22, 28, 22, 20),
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
                        color: HistoryEditGlassPanel.glassTextColor.withValues(alpha: 0.92),
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

/// 玻璃编辑区内标签文字色（固定浅灰，非主题 onShell 降 alpha）。
Color historyEditGlassLabelColor(BuildContext context) =>
    HistoryEditGlassPanel.glassLabelColor;

/// 玻璃编辑区内主文字色（固定浅色，保证深色玻璃底上可读）。
Color historyEditGlassTextColor(BuildContext context) =>
    HistoryEditGlassPanel.glassTextColor;

/// Shell 上胶囊/顶栏主文字（随 [AppVisualTokens.onShell]，经典浅色为深色字）。
Color historyEditGlassShellTextColor(BuildContext context) {
  final tokens = visualTokensOf(context);
  return tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
}

/// Shell 上胶囊标签、辅助图标色。
Color historyEditGlassShellLabelColor(BuildContext context) =>
    historyEditGlassShellTextColor(context).withValues(alpha: 0.62);

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
    this.onShell = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;
  final double minHeight;
  final bool onShell;

  @override
  Widget build(BuildContext context) {
    final tokens = visualTokensOf(context);
    final scheme = Theme.of(context).colorScheme;
    final fill = onShell && tokens != null
        ? tokens.pillBackground
        : onShell
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.06);
    final borderColor = onShell && tokens != null
        ? tokens.pillBorder
        : onShell
            ? scheme.outlineVariant.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.18);

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
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
