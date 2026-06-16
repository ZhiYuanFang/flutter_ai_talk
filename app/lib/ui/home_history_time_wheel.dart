import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/history_line_format.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

DateTime homeHistoryDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime homeHistoryClampCalendarDay(DateTime day, DateTime minimumDate, DateTime maximumDate) {
  final d = homeHistoryDateOnly(day);
  final min = homeHistoryDateOnly(minimumDate);
  final max = homeHistoryDateOnly(maximumDate);
  if (d.isBefore(min)) return min;
  if (d.isAfter(max)) return max;
  return d;
}

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

/// 历史编辑：日期文字展示，点击后弹出日期滚轮。
class HomeHistoryDateField extends StatelessWidget {
  const HomeHistoryDateField({
    super.key,
    required this.minimumDate,
    required this.maximumDate,
    this.value,
    this.anchorDate,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.placeholder = '未设置',
    this.glassStyle = false,
  });

  final DateTime minimumDate;
  final DateTime maximumDate;
  final DateTime? value;
  final DateTime? anchorDate;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;
  final String? label;
  final String placeholder;
  final bool glassStyle;

  static String formatDayLabel(DateTime? time, DateTime nowLocal) {
    if (time == null) return '';
    return formatHistoryDaySectionLabel(time, nowLocal);
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || onChanged == null) return;
    final anchor = value ?? anchorDate ?? DateTime.now();
    final picked = await showHomeHistoryDatePickerSheet(
      context,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
      initialValue: anchor,
      title: label,
    );
    if (picked == null) return;
    final base = value ?? anchor;
    onChanged!(DateTime(picked.year, picked.month, picked.day, base.hour, base.minute));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final display = value != null ? formatDayLabel(value, now) : placeholder;
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      Icon(Icons.calendar_today_outlined, size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          display,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isUnset ? scheme.onSurfaceVariant : scheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (enabled) Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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

/// 历史编辑：同一标签下并排日期与时间。
class HomeHistoryDateTimeRow extends StatelessWidget {
  const HomeHistoryDateTimeRow({
    super.key,
    required this.minimumDate,
    required this.maximumDate,
    required this.anchorDate,
    this.value,
    this.onChanged,
    this.onDateChanged,
    this.onTimeChanged,
    this.enabled = true,
    this.label,
    this.placeholder = '未设置',
  });

  final DateTime minimumDate;
  final DateTime maximumDate;
  final DateTime anchorDate;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final ValueChanged<DateTime>? onDateChanged;
  final ValueChanged<DateTime>? onTimeChanged;
  final bool enabled;
  final String? label;
  final String placeholder;

  DateTime get _timeAnchor {
    final v = value;
    if (v != null) return homeHistoryDateOnly(v);
    return homeHistoryDateOnly(anchorDate);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = historyEditGlassLabelColor(context);
    return Column(
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HomeHistoryDateField(
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                value: value,
                anchorDate: anchorDate,
                enabled: enabled,
                placeholder: placeholder,
                glassStyle: true,
                onChanged: onDateChanged ?? onChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HomeHistoryTimeField(
                anchorDate: _timeAnchor,
                value: value,
                enabled: enabled,
                placeholder: placeholder,
                glassStyle: true,
                onChanged: onTimeChanged ?? onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 弹出日期滚轮 Sheet；色调跟随 Material [ColorScheme.primary]。
Future<DateTime?> showHomeHistoryDatePickerSheet(
  BuildContext context, {
  required DateTime minimumDate,
  required DateTime maximumDate,
  required DateTime initialValue,
  String? title,
}) {
  return showGlassAdaptiveBottomSheet<DateTime>(
    context: context,
    scrollable: false,
    bodyBuilder: (ctx) => _HomeHistoryDatePickerSheetBody(
      minimumDate: minimumDate,
      maximumDate: maximumDate,
      initialValue: initialValue,
      title: title,
    ),
  );
}

class _HomeHistoryDatePickerSheetBody extends StatefulWidget {
  const _HomeHistoryDatePickerSheetBody({
    required this.minimumDate,
    required this.maximumDate,
    required this.initialValue,
    this.title,
  });

  final DateTime minimumDate;
  final DateTime maximumDate;
  final DateTime initialValue;
  final String? title;

  @override
  State<_HomeHistoryDatePickerSheetBody> createState() => _HomeHistoryDatePickerSheetBodyState();
}

class _HomeHistoryDatePickerSheetBodyState extends State<_HomeHistoryDatePickerSheetBody> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = homeHistoryClampCalendarDay(
      widget.initialValue,
      widget.minimumDate,
      widget.maximumDate,
    );
  }

  void _confirm() => Navigator.pop(context, homeHistoryDateOnly(_selectedDate));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final min = homeHistoryDateOnly(widget.minimumDate);
    final max = homeHistoryDateOnly(widget.maximumDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glassText),
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
                      color: glassText,
                    ),
                pickerTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: glassLabel,
                    ),
              ),
            ),
            child: SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: min,
                maximumDate: max,
                onDateTimeChanged: (date) {
                  setState(() => _selectedDate = homeHistoryClampCalendarDay(date, min, max));
                },
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

/// 弹出时/分滚轮 Sheet；色调跟随 Material [ColorScheme.primary]。
Future<DateTime?> showHomeHistoryTimePickerSheet(
  BuildContext context, {
  required DateTime anchorDate,
  required DateTime initialValue,
  String? title,
}) {
  return showGlassAdaptiveBottomSheet<DateTime>(
    context: context,
    scrollable: false,
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
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glassText),
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
                      color: glassText,
                    ),
                pickerTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: glassLabel,
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
                              color: glassText,
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
                              color: glassText,
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
