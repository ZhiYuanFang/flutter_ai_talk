import 'package:flutter/material.dart';

/// 底部弹层：最大高度为屏高 2/3，内容不足时 intrinsic，溢出内滚。
class AppAdaptiveBottomSheet extends StatelessWidget {
  const AppAdaptiveBottomSheet({
    super.key,
    required this.child,
    this.showDragHandle = false,
    this.maxHeightFraction = 2 / 3,
    this.scrollable = true,
    this.bottomExtraPadding = 0,
    this.respectKeyboardInset = false,
  });

  final Widget child;
  final bool showDragHandle;
  final double maxHeightFraction;
  final bool scrollable;
  final double bottomExtraPadding;
  final bool respectKeyboardInset;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * maxHeightFraction;
    final keyboardInset = respectKeyboardInset ? media.viewInsets.bottom : 0.0;
    final bottomPad = keyboardInset + media.viewPadding.bottom + bottomExtraPadding;
    const handleBlockHeight = 20.0;
    final handleHeight = showDragHandle ? handleBlockHeight : 0.0;
    final contentMaxH = (maxH - bottomPad - handleHeight).clamp(0.0, maxH);

    final content = scrollable
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: contentMaxH),
            child: SingleChildScrollView(child: child),
          )
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: contentMaxH),
            child: child,
          );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (scrollable) Flexible(child: content) else content,
          ],
        ),
      ),
    );
  }
}

/// 统一底部 Sheet 入口（`isScrollControlled: true`，最大 2/3 屏高）。
Future<T?> showAppAdaptiveBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder bodyBuilder,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    shape: shape,
    builder: (ctx) => AppAdaptiveBottomSheet(
      showDragHandle: !showDragHandle,
      child: bodyBuilder(ctx),
    ),
  );
}
