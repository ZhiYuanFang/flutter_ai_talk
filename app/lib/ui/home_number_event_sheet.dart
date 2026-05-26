import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/event_number_memory_store.dart';
import '../data/event_definition.dart';
import '../data/history_mapper.dart';
import 'event_logo.dart';
import 'home_event_number_picker.dart';
import 'home_history_edit_glass_panel.dart';
import 'home_history_time_wheel.dart';
import 'widgets/app_glass_overlay.dart';

/// number 类型事件二级页确认结果。
class HomeNumberEventResult {
  const HomeNumberEventResult({
    required this.startTime,
    required this.eventNumber,
    required this.remark,
  });

  final DateTime startTime;
  final int eventNumber;
  final String remark;
}

/// number 事件：玻璃态 Sheet，时刻 + Cupertino 滚轮用量 + 可选 remark。
///
/// [initialUsage] 非空时滚轮从该用量起选（编辑场景传原奶量）；否则读取本地上次记忆。
Future<HomeNumberEventResult?> showHomeNumberEventSheet(
  BuildContext context,
  EventDefinition event, {
  int? initialUsage,
}) {
  return showGlassAdaptiveBottomSheet<HomeNumberEventResult>(
    context: context,
    maxHeightFraction: 4 / 5,
    enableDrag: false,
    wrapInGlassPanel: false,
    bodyBuilder: (ctx) => _HomeNumberEventSheet(
      event: event,
      initialUsage: initialUsage,
    ),
  );
}

class _HomeNumberEventSheet extends StatefulWidget {
  const _HomeNumberEventSheet({
    required this.event,
    this.initialUsage,
  });

  final EventDefinition event;
  final int? initialUsage;

  @override
  State<_HomeNumberEventSheet> createState() => _HomeNumberEventSheetState();
}

class _HomeNumberEventSheetState extends State<_HomeNumberEventSheet> {
  late DateTime _selectedTime;
  late FixedExtentScrollController _usagePickerCtrl;
  final _remarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTime = DateTime.now();
    _usagePickerCtrl = FixedExtentScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialPickerIndex());
  }

  Future<void> _applyInitialPickerIndex() async {
    final usage =
        widget.initialUsage ?? await EventNumberMemoryStore.load(widget.event.id);
    if (!mounted) return;
    final idx = usage != null
        ? HomeEventNumberPicker.indexForValue(usage)
        : 0;
    if (_usagePickerCtrl.hasClients) {
      _usagePickerCtrl.jumpToItem(idx);
    }
  }

  @override
  void dispose() {
    _usagePickerCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    Navigator.pop(context);
  }

  DateTime get _todayAnchor {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _withTodayDate(DateTime t) {
    final a = _todayAnchor;
    return DateTime(a.year, a.month, a.day, t.hour, t.minute);
  }

  void _onTimeChanged(DateTime picked) {
    setState(() => _selectedTime = _withTodayDate(picked));
  }

  void _confirm() {
    final index = _usagePickerCtrl.hasClients ? _usagePickerCtrl.selectedItem : 0;
    final usage = HomeEventNumberPicker.valueAtIndex(index);
    if (widget.initialUsage == null) {
      unawaited(EventNumberMemoryStore.save(widget.event.id, usage));
    }
    Navigator.pop(
      context,
      HomeNumberEventResult(
        startTime: _withTodayDate(_selectedTime),
        eventNumber: usage,
        remark: _remarkCtrl.text.trim(),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final accent = resolveEventColor(context, widget.event);
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final dateLabel = formatHistoryApiDateTime(_todayAnchor).substring(0, 10);

    return HistoryEditGlassPanel(
      eventAccent: accent,
      onClose: _dismiss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: EventLogo(definition: widget.event, size: 44)),
          const SizedBox(height: 10),
          Text(
            widget.event.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dateLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: glassLabel,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          HomeHistoryTimeField(
            anchorDate: _todayAnchor,
            value: _selectedTime,
            label: '时间',
            glassStyle: true,
            onChanged: _onTimeChanged,
          ),
          const SizedBox(height: 14),
          Text('用量', style: TextStyle(fontSize: 13, color: glassLabel)),
          const SizedBox(height: 6),
          _glassPickerFrame(
            child: CupertinoTheme(
              data: const CupertinoThemeData(brightness: Brightness.dark),
              child: HomeEventNumberPicker(controller: _usagePickerCtrl),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _remarkCtrl,
            style: TextStyle(color: glassText, fontSize: 15),
            cursorColor: accent,
            decoration: historyEditGlassInputDecoration(context, labelText: '备注（可选）'),
            textInputAction: TextInputAction.done,
            maxLines: 2,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
              child: const Text('确认记录'),
            ),
          ),
        ],
      ),
    );
  }
}
