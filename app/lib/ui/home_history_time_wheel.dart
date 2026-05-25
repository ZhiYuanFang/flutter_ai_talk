import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'home_history_edit_glass_panel.dart';
import 'widgets/app_adaptive_bottom_sheet.dart';

/// 历史编辑：先展示时分，点击后弹出滚轮选择（日历日由 [anchorDate] 锚定）。
class HomeHistoryTimeField extends StatelessWidget {
  const HomeHistoryTimeField({
    super.key,
    required this.anchorDate,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.placeholder = '未设置',
    this.glassStyle = false,
  });

  final DateTime anchorDate;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;
  final String? label;
  final String placeholder;
  final bool glassStyle;

  static String formatHm(DateTime? time) {
    if (time == null) return '';
    String p2(int x) => x.toString().padLeft(2, '0');
    return '${p2(time.hour)}:${p2(time.minute)}';
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || onChanged == null) return;
    final picked = await showHomeHistoryTimePickerSheet(
      context,
      anchorDate: anchorDate,
      initialValue: value ?? anchorDate,
      title: label,
    );
    if (picked != null) onChanged!(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = value != null ? formatHm(value) : placeholder;
    final isUnset = value == null;

    if (glassStyle) {
      final labelColor = historyEditGlassLabelColor(context);
      final textColor = historyEditGlassTextColor(context);
      return IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              HistoryEditGlassTapField(
                enabled: enabled,
                onTap: enabled ? () => _openPicker(context) : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: isUnset
                              ? HistoryEditGlassPanel.glassLabelColor.withValues(alpha: 0.65)
                              : textColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (enabled)
                      const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: HistoryEditGlassPanel.glassLabelColor,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (label != null) ...[
              Text(label!, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
            ],
            Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: enabled ? () => _openPicker(context) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          display,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isUnset
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                      ),
                      if (enabled)
                        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹出时/分滚轮 Sheet；色调跟随 Material [ColorScheme.primary]。
Future<DateTime?> showHomeHistoryTimePickerSheet(
  BuildContext context, {
  required DateTime anchorDate,
  required DateTime initialValue,
  String? title,
}) {
  return showAppAdaptiveBottomSheet<DateTime>(
    context: context,
    bodyBuilder: (ctx) => _HomeHistoryTimePickerSheetBody(
      anchorDate: anchorDate,
      initialValue: initialValue,
      title: title,
    ),
  );
}

class _HomeHistoryTimePickerSheetBody extends StatefulWidget {
  const _HomeHistoryTimePickerSheetBody({
    required this.anchorDate,
    required this.initialValue,
    this.title,
  });

  final DateTime anchorDate;
  final DateTime initialValue;
  final String? title;

  @override
  State<_HomeHistoryTimePickerSheetBody> createState() => _HomeHistoryTimePickerSheetBodyState();
}

class _HomeHistoryTimePickerSheetBodyState extends State<_HomeHistoryTimePickerSheetBody> {
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    final t = widget.initialValue;
    _hourCtrl = FixedExtentScrollController(initialItem: t.hour.clamp(0, 23));
    _minuteCtrl = FixedExtentScrollController(initialItem: t.minute.clamp(0, 59));
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  DateTime _selected() {
    final a = widget.anchorDate;
    return DateTime(
      a.year,
      a.month,
      a.day,
      _hourCtrl.selectedItem,
      _minuteCtrl.selectedItem,
    );
  }

  void _confirm() => Navigator.pop(context, _selected());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: primary,
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                pickerTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
              ),
            ),
            child: SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _hourCtrl,
                      itemExtent: 36,
                      onSelectedItemChanged: (_) {},
                      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                        background: primary.withValues(alpha: 0.12),
                      ),
                      children: List.generate(
                        24,
                        (i) => Center(
                          child: Text(
                            '${i.toString().padLeft(2, '0')} 时',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _minuteCtrl,
                      itemExtent: 36,
                      onSelectedItemChanged: (_) {},
                      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                        background: primary.withValues(alpha: 0.12),
                      ),
                      children: List.generate(
                        60,
                        (i) => Center(
                          child: Text(
                            '${i.toString().padLeft(2, '0')} 分',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
