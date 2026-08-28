import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import 'home_event_number_picker.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

/// 玻璃单列滚轮 Sheet：与用量轮同壳（字色 / 高亮条 / fieldFill 内框）。
/// 确认返回选中 index；取消/关闭返回 null。
/// [title] 与 [titleWidget] 二选一；[titleWidget] 用于 logo+事件名等复合标题。
Future<int?> showGlassSingleWheelPickerSheet(
  BuildContext context, {
  String? title,
  Widget? titleWidget,
  required List<String> labels,
  required int initialIndex,
}) {
  assert(labels.isNotEmpty);
  assert(title != null || titleWidget != null);
  final clamped = initialIndex.clamp(0, labels.length - 1);
  return showGlassAdaptiveBottomSheet<int>(
    context: context,
    scrollable: false,
    bodyBuilder: (ctx) => _GlassSingleWheelPickerBody(
      title: title,
      titleWidget: titleWidget,
      labels: labels,
      initialIndex: clamped,
    ),
  );
}

class _GlassSingleWheelPickerBody extends StatefulWidget {
  const _GlassSingleWheelPickerBody({
    this.title,
    this.titleWidget,
    required this.labels,
    required this.initialIndex,
  });

  final String? title;
  final Widget? titleWidget;
  final List<String> labels;
  final int initialIndex;

  @override
  State<_GlassSingleWheelPickerBody> createState() =>
      _GlassSingleWheelPickerBodyState();
}

class _GlassSingleWheelPickerBodyState
    extends State<_GlassSingleWheelPickerBody> {
  late FixedExtentScrollController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = FixedExtentScrollController(initialItem: _index);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.pop(context, _index);

  @override
  Widget build(BuildContext context) {
    final primary = AppColor.primary(context);
    final onPrimary = AppColor.onPrimary(context);
    final onSheet = historyEditGlassTextColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.titleWidget != null)
            widget.titleWidget!
          else
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onSheet,
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          // 与用量滚轮外框一致
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.fieldBorder(context)),
              color: AppColor.fieldFill(context),
            ),
            child: SizedBox(
              height: kHomeEventNumberPickerHeight,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                  primaryColor: primary,
                  textTheme: CupertinoTextThemeData(
                    pickerTextStyle: TextStyle(
                      color: onSheet,
                      fontSize: 16,
                    ),
                  ),
                ),
                child: CupertinoPicker(
                  scrollController: _ctrl,
                  itemExtent: kHomeEventNumberPickerItemExtent,
                  onSelectedItemChanged: (i) => _index = i,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: primary.withValues(alpha: 0.12),
                  ),
                  children: [
                    for (final label in widget.labels)
                      Center(
                        child: Text(
                          label,
                          style: TextStyle(color: onSheet),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
            ),
            onPressed: _confirm,
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
