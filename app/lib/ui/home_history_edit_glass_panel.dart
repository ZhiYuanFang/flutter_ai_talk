import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';

/// 历史编辑 Sheet 玻璃拟态容器：底/边/字走 sheet/modal 原子；事件色仅强调渐变。
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

  @override
  Widget build(BuildContext context) {
    final fillTop = AppColor.sheetFill(context);
    final onSheet = AppColor.textOnSheet(context);
    final border = AppColor.sheetBorder(context);
    // 事件 accent：仅渐变强调
    final accent = eventAccent ?? AppColor.primary(context);
    final fillBottom = Color.alphaBlend(
      accent.withValues(alpha: 0.2),
      fillTop,
    );
    final radius = borderRadius ?? _radius;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border),
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
                  padding: contentPadding ??
                      const EdgeInsets.fromLTRB(22, 28, 22, 20),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: onSheet),
                    child: child,
                  ),
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
                        color: onSheet.withValues(alpha: 0.92),
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
Color historyEditGlassLabelColor(BuildContext context) =>
    AppColor.textOnSheet(context).withValues(alpha: 0.78);

/// 玻璃编辑区内主文字色。
Color historyEditGlassTextColor(BuildContext context) =>
    AppColor.textOnSheet(context);

/// Shell 上胶囊/顶栏主文字。
Color historyEditGlassShellTextColor(BuildContext context) =>
    AppColor.textPrimary(context);

/// Shell 上胶囊标签、辅助图标色。
Color historyEditGlassShellLabelColor(BuildContext context) =>
    AppColor.textMuted(context);

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
    fillColor: AppColor.fieldFill(context).withValues(alpha: 0.85),
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: AppColor.fieldBorder(context)),
    ),
    border: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

OutlineInputBorder historyEditGlassFieldBorder(BuildContext context) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppColor.fieldBorder(context)),
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
    final fill = onShell
        ? (tokens?.pillBackground ?? AppColor.surface(context))
        : AppColor.fieldFill(context);
    final borderColor = onShell
        ? (tokens?.pillBorder ?? AppColor.divider(context))
        : AppColor.fieldBorder(context);

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
