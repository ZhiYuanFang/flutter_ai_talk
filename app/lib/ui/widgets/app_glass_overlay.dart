import 'package:flutter/material.dart';

import '../home_history_edit_glass_panel.dart';
import 'app_adaptive_bottom_sheet.dart';

/// 玻璃拟态底部 Sheet：透明外层 + 可选事件色 accent + 内层 [HistoryEditGlassPanel]。
Future<T?> showGlassAdaptiveBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder bodyBuilder,
  Color? eventAccent,
  VoidCallback? onClose,
  EdgeInsets? glassContentPadding,
  double maxHeightFraction = 2 / 3,
  double horizontalPadding = 16,
  double bottomExtraPadding = 12,
  bool showDragHandle = false,
  bool enableDrag = true,
  bool isDismissible = true,
  bool wrapInGlassPanel = true,
  bool scrollable = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    useRootNavigator: useRootNavigator,
    builder: (ctx) {
      Widget inner = bodyBuilder(ctx);
      if (wrapInGlassPanel) {
        inner = HistoryEditGlassPanel(
          eventAccent: eventAccent,
          onClose: onClose ?? () => Navigator.pop(ctx),
          contentPadding: glassContentPadding,
          child: inner,
        );
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 0),
        child: AppAdaptiveBottomSheet(
          showDragHandle: showDragHandle,
          maxHeightFraction: maxHeightFraction,
          scrollable: scrollable,
          bottomExtraPadding: bottomExtraPadding,
          child: inner,
        ),
      );
    },
  );
}

/// 居中玻璃对话框。
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder contentBuilder,
  Color? eventAccent,
  VoidCallback? onClose,
  double maxWidth = 340,
  double? maxHeightFraction,
  bool barrierDismissible = true,
  bool wrapInGlassPanel = true,
  bool useRootNavigator = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      final maxH = maxHeightFraction != null
          ? MediaQuery.sizeOf(dialogContext).height * maxHeightFraction
          : null;
      Widget inner = contentBuilder(dialogContext);
      if (wrapInGlassPanel) {
        inner = HistoryEditGlassPanel(
          eventAccent: eventAccent,
          onClose: onClose,
          child: inner,
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxH ?? double.infinity,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: inner,
            ),
          ),
        ),
      );
    },
  );
}

/// 玻璃确认对话框（标题 + 正文 + 取消/确认）。
Future<bool?> showGlassConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool useRootNavigator = true,
}) {
  return showGlassDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: glassLabel,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(cancelLabel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// 玻璃文本验证对话框（标题 + 正文 + 验证输入 + 取消/确认）。
Future<bool?> showGlassTextConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String expectedText,
  String hintText = '请输入以确认',
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool useRootNavigator = true,
}) {
  return showGlassDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    contentBuilder: (ctx) {
      return _GlassTextConfirmDialogBody(
        title: title,
        message: message,
        expectedText: expectedText,
        hintText: hintText,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
      );
    },
  );
}

class _GlassTextConfirmDialogBody extends StatefulWidget {
  const _GlassTextConfirmDialogBody({
    required this.title,
    required this.message,
    required this.expectedText,
    required this.hintText,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String expectedText;
  final String hintText;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<_GlassTextConfirmDialogBody> createState() => _GlassTextConfirmDialogBodyState();
}

class _GlassTextConfirmDialogBodyState extends State<_GlassTextConfirmDialogBody> {
  late final TextEditingController _controller;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_updateCanConfirm);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateCanConfirm() {
    final cur = _controller.text == widget.expectedText;
    if (cur != _canConfirm) {
      setState(() => _canConfirm = cur);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: glassText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          style: TextStyle(color: glassText, fontSize: 16),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: glassLabel.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: glassLabel.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: glassLabel.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: glassLabel,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(widget.cancelLabel),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _canConfirm ? () => Navigator.pop(context, true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: const StadiumBorder(),
                disabledBackgroundColor: scheme.primary.withValues(alpha: 0.3),
                disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.5),
              ),
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ],
    );
  }
}
