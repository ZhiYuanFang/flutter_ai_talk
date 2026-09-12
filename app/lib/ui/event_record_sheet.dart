import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/event_number_memory_store.dart';
import '../config/event_remark_memory_store.dart';
import '../data/event_definition.dart';
import '../data/models.dart';
import '../providers/home_history_notifier.dart';
import '../providers/settings_baby.dart';
import '../theme/app_color.dart';
import 'event_logo.dart';
import 'home_event_number_picker.dart';
import 'home_history_edit_glass_panel.dart';
import 'home_history_edit_sheet.dart';
import 'home_history_time_wheel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/event_remark_quick_tags.dart';
import 'widgets/keyboard_dismiss_scope.dart';
import 'widgets/keyboard_input_bridge.dart';
import 'widgets/keyboard_lift.dart';

/// 统一记录 Sheet 操作意图。
enum EventRecordIntent {
  /// 补记过去（预测无 lastAt）。
  supplement,

  /// 普通新增（喂养格 / 有 lastAt 点卡等）。
  add,

  /// 编辑已有历史。
  edit,
}

/// 创建 / 补充确认结果。
class EventRecordCreateResult {
  const EventRecordCreateResult({
    required this.startTime,
    required this.endTime,
    required this.eventNumber,
    required this.remark,
  });

  final DateTime startTime;
  /// null 表示计时进行中。
  final DateTime? endTime;
  final int eventNumber;
  final String remark;
}

/// 统一入口：edit 转历史编辑；add/supplement 打开创建 Sheet。
Future<Object?> showEventRecordSheet(
  BuildContext context, {
  required EventRecordIntent intent,
  EventDefinition? event,
  HistoryRecord? record,
  List<EventDefinition>? eventCatalog,
  HomeHistoryNotifier? history,
  int? initialUsage,
}) {
  if (intent == EventRecordIntent.edit) {
    assert(record != null && eventCatalog != null && history != null);
    return showHomeHistoryEditSheet(
      context,
      record: record!,
      eventCatalog: eventCatalog!,
      history: history!,
    );
  }
  assert(event != null);
  return showGlassAdaptiveBottomSheet<EventRecordCreateResult>(
    context: context,
    maxHeightFraction: 4 / 5,
    enableDrag: false,
    wrapInGlassPanel: false,
    respectKeyboardInset: true,
    bodyBuilder: (ctx) => _EventRecordCreateSheet(
      intent: intent,
      event: event!,
      initialUsage: initialUsage,
    ),
  );
}

/// 仅创建/补充，强类型返回。
Future<EventRecordCreateResult?> showEventRecordCreateSheet(
  BuildContext context, {
  required EventRecordIntent intent,
  required EventDefinition event,
  int? initialUsage,
}) async {
  assert(intent != EventRecordIntent.edit);
  final r = await showEventRecordSheet(
    context,
    intent: intent,
    event: event,
    initialUsage: initialUsage,
  );
  return r is EventRecordCreateResult ? r : null;
}

class _EventRecordCreateSheet extends ConsumerStatefulWidget {
  const _EventRecordCreateSheet({
    required this.intent,
    required this.event,
    this.initialUsage,
  });

  final EventRecordIntent intent;
  final EventDefinition event;
  final int? initialUsage;

  @override
  ConsumerState<_EventRecordCreateSheet> createState() =>
      _EventRecordCreateSheetState();
}

class _EventRecordCreateSheetState extends ConsumerState<_EventRecordCreateSheet> {
  late DateTime _start;
  DateTime? _end;
  late FixedExtentScrollController _usagePickerCtrl;
  final _remarkCtrl = TextEditingController();
  final _remarkFocusNode = FocusNode();
  final _remarkAnchorKey = GlobalKey();

  EventCatalogEventType get _type => widget.event.parsedEventType!;

  bool get _isTiming => _type == EventCatalogEventType.time;

  bool get _showUsage => _type == EventCatalogEventType.number;

  @override
  void initState() {
    super.initState();
    // 初值：今日 · 当下
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _end = null;
    _usagePickerCtrl = FixedExtentScrollController();
    _remarkFocusNode.addListener(_onRemarkFocusChange);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _applyInitialPickerIndex());
  }

  Future<void> _applyInitialPickerIndex() async {
    if (!_showUsage) return;
    final usage = widget.initialUsage ??
        await EventNumberMemoryStore.load(widget.event.id);
    if (!mounted) return;
    final idx =
        usage != null ? HomeEventNumberPicker.indexForValue(usage) : 0;
    if (_usagePickerCtrl.hasClients) {
      _usagePickerCtrl.jumpToItem(idx);
    }
  }

  @override
  void dispose() {
    _usagePickerCtrl.dispose();
    _remarkFocusNode.removeListener(_onRemarkFocusChange);
    _remarkFocusNode.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _onRemarkFocusChange() {
    handleBridgeFocusChange(
      context: context,
      focusNode: _remarkFocusNode,
      controller: _remarkCtrl,
      scene: 'event.record.create.remark',
      onConfirm: () => _remarkFocusNode.unfocus(),
      hint: '备注（可选）',
      anchorKey: _remarkAnchorKey,
    );
  }

  void _onRemarkTagSelected(String text) {
    _remarkCtrl.text = text;
    keyboardInputBridgeController.updateDraft(text);
    setState(() {});
  }

  void _onStartChanged(DateTime v) {
    setState(() {
      _start = v;
      final end = _end;
      if (_isTiming && end != null) {
        final startDay = homeHistoryDateOnly(v);
        final endDay = homeHistoryDateOnly(end);
        if (startDay.isAfter(endDay)) {
          _end = DateTime(
            startDay.year,
            startDay.month,
            startDay.day,
            end.hour,
            end.minute,
          );
        } else if (v.isAfter(end)) {
          _end = v;
        }
      }
    });
  }

  void _dismiss() => Navigator.pop(context);

  void _confirm() {
    final remark = _remarkCtrl.text.trim();
    unawaited(EventRemarkMemoryStore.save(widget.event.id, remark));

    late final int eventNumber;
    late final DateTime startTime;
    late final DateTime? endTime;

    switch (_type) {
      case EventCatalogEventType.time:
        eventNumber = 0;
        startTime = _start;
        endTime = _end;
      case EventCatalogEventType.one:
        eventNumber = 1;
        startTime = _start;
        endTime = _start;
      case EventCatalogEventType.number:
        final index =
            _usagePickerCtrl.hasClients ? _usagePickerCtrl.selectedItem : 0;
        eventNumber = HomeEventNumberPicker.valueAtIndex(index);
        if (widget.initialUsage == null) {
          unawaited(EventNumberMemoryStore.save(widget.event.id, eventNumber));
        }
        startTime = _start;
        endTime = _start;
    }

    Navigator.pop(
      context,
      EventRecordCreateResult(
        startTime: startTime,
        endTime: endTime,
        eventNumber: eventNumber,
        remark: remark,
      ),
    );
  }

  String get _title => widget.event.name;

  String get _confirmLabel {
    switch (widget.intent) {
      case EventRecordIntent.supplement:
        return '确认补充';
      case EventRecordIntent.add:
        return '确认记录';
      case EventRecordIntent.edit:
        return '保存';
    }
  }

  Widget _glassPickerFrame({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.fieldBorder(context)),
        color: AppColor.fieldFill(context),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = resolveEventColor(context, widget.event);
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final now = DateTime.now();
    final pickerMaxDate = homeHistoryDateOnly(now);
    final babyAsync = ref.watch(settingsBabyProvider);
    final pickerMinDate = babyAsync.maybeWhen(
      data: (baby) => homeHistoryDateOnly(baby.birthDate),
      orElse: () => DateTime(2000, 1, 1),
    );

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
            _title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: eventRecordAccentDeep(accent),
            ),
          ),
          const SizedBox(height: 20),
          HomeHistoryCenteredTimeLine(
            minimumDate: pickerMinDate,
            maximumDate: pickerMaxDate,
            start: _start,
            end: _end,
            showEndRange: _isTiming,
            accent: accent,
            onStartChanged: _onStartChanged,
            onEndChanged: (v) => setState(() => _end = v),
          ),
          if (_showUsage) ...[
            const SizedBox(height: 14),
            Text('用量', style: TextStyle(fontSize: 13, color: glassLabel)),
            const SizedBox(height: 6),
            _glassPickerFrame(
              child: HomeEventNumberPicker(controller: _usagePickerCtrl),
            ),
          ],
          const SizedBox(height: 14),
          keyboardLiftTarget(
            focusNode: _remarkFocusNode,
            anchorKey: _remarkAnchorKey,
            child: TextField(
              controller: _remarkCtrl,
              focusNode: _remarkFocusNode,
              style: TextStyle(color: glassText, fontSize: 15),
              cursorColor: accent,
              decoration: historyEditGlassInputDecoration(
                context,
                labelText: '备注（可选）',
              ),
              textInputAction: TextInputAction.done,
              maxLines: 2,
              onChanged: keyboardInputBridgeController.updateDraft,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          KeyboardDismissExclude(
            child: EventRemarkQuickTags(
              eventId: widget.event.id,
              onSelect: _onRemarkTagSelected,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: const StadiumBorder(),
              ),
              child: Text(_confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
