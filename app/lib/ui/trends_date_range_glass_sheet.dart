import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/trends_date_range_store.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

/// 玻璃态底部 Sheet 选择趋势起止日期（本地自然日）。
Future<TrendsDateRange?> showTrendsDateRangeGlassSheet(
  BuildContext context, {
  required DateTime initialStart,
  required DateTime initialEnd,
  Color? eventAccent,
}) {
  return showGlassAdaptiveBottomSheet<TrendsDateRange>(
    context: context,
    maxHeightFraction: 4 / 5,
    enableDrag: false,
    eventAccent: eventAccent,
    wrapInGlassPanel: false,
    bodyBuilder: (ctx) => _TrendsDateRangeGlassSheetBody(
      initialStart: initialStart,
      initialEnd: initialEnd,
      eventAccent: eventAccent,
    ),
  );
}

class _TrendsDateRangeGlassSheetBody extends StatefulWidget {
  const _TrendsDateRangeGlassSheetBody({
    required this.initialStart,
    required this.initialEnd,
    this.eventAccent,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final Color? eventAccent;

  @override
  State<_TrendsDateRangeGlassSheetBody> createState() => _TrendsDateRangeGlassSheetBodyState();
}

class _TrendsDateRangeGlassSheetBodyState extends State<_TrendsDateRangeGlassSheetBody> {
  static final _displayFmt = DateFormat('yyyy-MM-dd');
  static final _minDate = DateTime(2020, 1, 1);

  late DateTime _start;
  late DateTime _end;

  DateTime get _today => TrendsDateRangeLogic.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _start = TrendsDateRangeLogic.dateOnly(widget.initialStart);
    _end = TrendsDateRangeLogic.dateOnly(widget.initialEnd);
    _clampEndToStart();
  }

  DateTime _maxEndForStart(DateTime start) {
    final capBySpan = start.add(
      const Duration(days: TrendsDateRangeLogic.maxInclusiveDays - 1),
    );
    final cap = TrendsDateRangeLogic.dateOnly(capBySpan);
    return cap.isAfter(_today) ? _today : cap;
  }

  void _clampEndToStart() {
    if (_end.isBefore(_start)) _end = _start;
    final maxEnd = _maxEndForStart(_start);
    if (_end.isAfter(maxEnd)) _end = maxEnd;
  }

  void _onStartChanged(DateTime raw) {
    setState(() {
      _start = TrendsDateRangeLogic.dateOnly(raw);
      _clampEndToStart();
    });
  }

  void _onEndChanged(DateTime raw) {
    setState(() {
      _end = TrendsDateRangeLogic.dateOnly(raw);
      if (_end.isBefore(_start)) _end = _start;
      final maxEnd = _maxEndForStart(_start);
      if (_end.isAfter(maxEnd)) _end = maxEnd;
    });
  }

  void _confirm() {
    if (!TrendsDateRangeLogic.isValidSpan(_start, _end)) {
      showAppToast(
        '日期跨度不能超过${TrendsDateRangeLogic.maxInclusiveDays}天',
        tone: AppToastTone.error,
      );
      return;
    }
    Navigator.pop(context, TrendsDateRange(start: _start, end: _end));
  }

  Widget _glassPickerFrame({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: child,
    );
  }

  double _pickerHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final h = size.height;
    if (landscape) return 100;
    if (h < 640) return 120;
    if (h < 760) return 150;
    return 168;
  }

  Widget _datePickerSection({
    required String label,
    required DateTime value,
    required DateTime minimumDate,
    required DateTime maximumDate,
    required ValueChanged<DateTime> onChanged,
    required double pickerHeight,
  }) {
    final glassLabel = historyEditGlassLabelColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: glassLabel,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _displayFmt.format(value),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: historyEditGlassTextColor(context),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        _glassPickerFrame(
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: SizedBox(
              height: pickerHeight,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: value,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                onDateTimeChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.eventAccent ?? scheme.primary;
    final glassText = historyEditGlassTextColor(context);
    final maxEnd = _maxEndForStart(_start);
    final pickerH = _pickerHeight(context);

    return HistoryEditGlassPanel(
      eventAccent: accent,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '选择日期范围',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '最多 ${TrendsDateRangeLogic.maxInclusiveDays} 天（含起止日）',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: historyEditGlassLabelColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _datePickerSection(
            label: '开始日期',
            value: _start,
            minimumDate: _minDate,
            maximumDate: _today,
            onChanged: _onStartChanged,
            pickerHeight: pickerH,
          ),
          const SizedBox(height: 14),
          _datePickerSection(
            label: '结束日期',
            value: _end,
            minimumDate: _start,
            maximumDate: maxEnd,
            onChanged: _onEndChanged,
            pickerHeight: pickerH,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: const StadiumBorder(),
              ),
              child: const Text('确定'),
            ),
          ),
        ],
      ),
    );
  }
}
