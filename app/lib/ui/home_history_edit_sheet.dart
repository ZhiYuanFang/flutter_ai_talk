import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/models.dart';
import '../providers/home_history_notifier.dart';
import '../providers/repositories.dart';
import 'event_logo.dart';
import 'home_event_number_picker.dart';
import 'home_history_edit_glass_panel.dart';
import 'home_history_time_wheel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/keyboard_input_bridge.dart';

/// 主页历史行编辑：玻璃拟态底部 Sheet，返回 `true` 表示列表已变更。
Future<bool?> showHomeHistoryEditSheet(
  BuildContext context, {
  required HistoryRecord record,
  required List<EventDefinition> eventCatalog,
  required HomeHistoryNotifier history,
  required Future<bool> Function(HistoryRecord) onStopActiveTimer,
}) {
  return showGlassAdaptiveBottomSheet<bool>(
    context: context,
    maxHeightFraction: 4 / 5,
    enableDrag: false,
    wrapInGlassPanel: false,
    bodyBuilder: (ctx) => _HomeHistoryEditSheetBody(
      recordId: record.id,
      eventCatalog: eventCatalog,
      history: history,
      onStopActiveTimer: onStopActiveTimer,
    ),
  );
}

class _HomeHistoryEditSheetBody extends ConsumerStatefulWidget {
  const _HomeHistoryEditSheetBody({
    required this.recordId,
    required this.eventCatalog,
    required this.history,
    required this.onStopActiveTimer,
  });

  final String recordId;
  final List<EventDefinition> eventCatalog;
  final HomeHistoryNotifier history;
  final Future<bool> Function(HistoryRecord) onStopActiveTimer;

  @override
  ConsumerState<_HomeHistoryEditSheetBody> createState() => _HomeHistoryEditSheetBodyState();
}

class _HomeHistoryEditSheetBodyState extends ConsumerState<_HomeHistoryEditSheetBody> {
  final _remarkCtrl = TextEditingController();
  final _remarkFocusNode = FocusNode();
  late FixedExtentScrollController _usagePickerCtrl;

  HistoryRecord? _record;
  DateTime _startEdit = DateTime.now();
  DateTime? _endEdit;
  var _stoppingActive = false;
  var _saving = false;
  var _deleting = false;

  @override
  void initState() {
    super.initState();
    _usagePickerCtrl = FixedExtentScrollController();
    _remarkFocusNode.addListener(_onRemarkFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRecord());
  }

  @override
  void dispose() {
    _remarkFocusNode.removeListener(_onRemarkFocusChange);
    _remarkFocusNode.dispose();
    _remarkCtrl.dispose();
    _usagePickerCtrl.dispose();
    super.dispose();
  }

  void _onRemarkFocusChange() {
    if (_remarkFocusNode.hasFocus) {
      keyboardInputBridgeController.attach(
        controller: _remarkCtrl,
        focusNode: _remarkFocusNode,
        onConfirm: () => _remarkFocusNode.unfocus(),
        scene: 'home.history-edit.remark',
        hint: '备注',
      );
      return;
    }
    keyboardInputBridgeController.detach(controller: _remarkCtrl);
  }

  void _resolveRecord() {
    final items = ref.read(homeHistoryProvider).items;
    final idx = items.indexWhere((e) => e.id == widget.recordId);
    if (idx < 0) {
      showAppToast('记录不存在', tone: AppToastTone.error);
      if (mounted) Navigator.pop(context);
      return;
    }
    final r = items[idx];
    setState(() {
      _record = r;
      _applyRecordToForm(r);
    });
  }

  void _applyRecordToForm(HistoryRecord r) {
    final p = r.rawPayload;
    _remarkCtrl.text = (p['remark'] as String?) ?? '';
    _startEdit = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    _endEdit = parseHistoryInstant(p['endTime']);
    final n = historyPayloadInt(p, 'eventNumber');
    if ((n == 1 || n > 1) && _endEdit == null) {
      _endEdit = _startEdit;
    }
    if (n > 1) {
      final usage = historyPayloadInt(p, 'eventNumber');
      final idx = HomeEventNumberPicker.indexForValue(usage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_usagePickerCtrl.hasClients) {
          _usagePickerCtrl.jumpToItem(idx);
        }
      });
    }
  }

  bool get _pending => _record != null && isPendingHistoryId(_record!.id);

  String _displayEventName(HistoryRecord r) {
    final e = r.eventName.trim();
    return e.isEmpty ? '未知事件' : e;
  }

  HistoryRecord _recordAfterLocalUpdate(
    HistoryRecord r, {
    required String remark,
    DateTime? startTime,
    DateTime? endTime,
    int? usageCount,
    bool clearEnd = false,
  }) {
    final p = Map<String, Object?>.from(r.rawPayload);
    p['remark'] = remark;
    if (startTime != null) {
      p['startTime'] = historyDateTimeToUnixSeconds(startTime);
    }
    if (endTime != null) {
      p['endTime'] = historyDateTimeToUnixSeconds(endTime);
    } else if (clearEnd) {
      p['endTime'] = 0;
    }
    if (usageCount != null) {
      p['eventNumber'] = usageCount;
    }
    final action = remark.trim().isEmpty ? '—' : remark.trim();
    return HistoryRecord(
      id: r.id,
      createdAt: r.createdAt,
      eventName: r.eventName,
      action: action,
      rawPayload: p,
    );
  }

  bool _isFormDirty() {
    final r = _record;
    if (r == null || _pending) return false;
    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final remark = (p['remark'] as String?) ?? '';
    if (_remarkCtrl.text != remark) return true;

    final start = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    final end = parseHistoryInstant(p['endTime']);
    final endUnset = historyInstantUnset(end);

    if (n == 0) {
      if (_startEdit != start) return true;
      if (endUnset) {
        if (_endEdit != null) return true;
      } else if (end != null && (_endEdit == null || _endEdit != end)) {
        return true;
      }
      return false;
    }

    final endCompare = end ?? start;
    if (_endEdit == null || _endEdit != endCompare) return true;
    if (n > 1) {
      final usage = historyPayloadInt(p, 'eventNumber');
      final idx = _usagePickerCtrl.hasClients ? _usagePickerCtrl.selectedItem : 0;
      final picked = HomeEventNumberPicker.valueAtIndex(idx);
      if (picked != usage) return true;
    }
    return false;
  }

  Future<bool> _confirmDiscardEdits() async {
    return await showGlassConfirmDialog(
          context,
          title: '放弃修改？',
          message: '未保存的修改将丢失。',
          cancelLabel: '继续编辑',
          confirmLabel: '放弃',
        ) ??
        false;
  }

  Future<bool> _onMaybePop() async {
    if (!_isFormDirty()) return true;
    return _confirmDiscardEdits();
  }

  Future<void> _requestClose() async {
    if (!await _onMaybePop()) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _save() async {
    final r = _record;
    if (r == null || _pending || _saving) return;
    final n = historyPayloadInt(r.rawPayload, 'eventNumber');
    final repo = ref.read(feedRepositoryProvider);
    final remark = _remarkCtrl.text.trim();

    setState(() => _saving = true);
    HistoryRecord? updated;
    var ok = false;

    if (n == 0) {
      if (_endEdit != null && _endEdit!.isBefore(_startEdit)) {
        showAppToast('结束时间不能早于开始时间', tone: AppToastTone.error);
        setState(() => _saving = false);
        return;
      }
      ok = await repo.updateHistoryRecord(
        r.id,
        remark: remark,
        startTime: _startEdit,
        endTime: _endEdit,
        clearEndIfNull: true,
        fallbackRecord: r,
      );
      if (ok) {
        updated = _recordAfterLocalUpdate(
          r,
          remark: remark,
          startTime: _startEdit,
          endTime: _endEdit,
          clearEnd: _endEdit == null,
        );
      }
    } else if (n == 1) {
      if (_endEdit == null) {
        showAppToast('请选择结束时间', tone: AppToastTone.error);
        setState(() => _saving = false);
        return;
      }
      ok = await repo.updateHistoryRecord(
        r.id,
        remark: remark,
        startTime: _endEdit,
        endTime: _endEdit,
        fallbackRecord: r,
      );
      if (ok) {
        updated = _recordAfterLocalUpdate(
          r,
          remark: remark,
          startTime: _endEdit,
          endTime: _endEdit,
        );
      }
    } else {
      if (_endEdit == null) {
        showAppToast('请选择结束时间', tone: AppToastTone.error);
        setState(() => _saving = false);
        return;
      }
      final idx = _usagePickerCtrl.hasClients ? _usagePickerCtrl.selectedItem : 0;
      final usage = HomeEventNumberPicker.valueAtIndex(idx);
      ok = await repo.updateHistoryRecord(
        r.id,
        remark: remark,
        startTime: _endEdit,
        endTime: _endEdit,
        usageCount: usage,
        fallbackRecord: r,
      );
      if (ok) {
        updated = _recordAfterLocalUpdate(
          r,
          remark: remark,
          startTime: _endEdit,
          endTime: _endEdit,
          usageCount: usage,
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok || updated == null) return;
    widget.history.replaceRecord(updated);
    showAppToast('已保存', tone: AppToastTone.success);
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final r = _record;
    if (r == null || _pending || _deleting) return;
    final go = await showGlassConfirmDialog(
          context,
          title: '删除事件',
          message: '确定删除该条历史记录？此操作不可撤销。',
          confirmLabel: '删除',
        ) ??
        false;
    if (!go || !mounted) return;
    setState(() => _deleting = true);
    final ok = await ref.read(feedRepositoryProvider).deleteHistoryRecord(r.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (!ok) return;
    widget.history.removeRecord(r.id);
    showAppToast('已删除', tone: AppToastTone.success);
    Navigator.pop(context, true);
  }

  Future<void> _stopActiveTiming() async {
    final r = _record;
    if (r == null || _pending || _stoppingActive || !isActiveTimingRecord(r)) return;
    setState(() => _stoppingActive = true);
    final ok = await widget.onStopActiveTimer(r);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _stoppingActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = _record;
    if (r == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final unit = (p['eventUnit'] as String?)?.trim() ?? '';
    final eventDef = lookupEventForRecord(widget.eventCatalog, r);
    final accent = resolveEventColor(context, eventDef);
    final readOnly = _pending;
    final showStop = !readOnly && n == 0 && isActiveTimingRecord(r);
    final scheme = Theme.of(context).colorScheme;
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);

    final startAnchor = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    final endAnchor = _endEdit ?? parseHistoryInstant(p['endTime']) ?? startAnchor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestClose();
      },
      child: HistoryEditGlassPanel(
        eventAccent: accent,
        onClose: _requestClose,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (readOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '同步中…',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Center(child: EventLogo(definition: eventDef, size: 44)),
            const SizedBox(height: 10),
            Text(
              _displayEventName(r),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: glassText,
              ),
            ),
            const SizedBox(height: 20),
            if (n == 0) ...[
              HomeHistoryTimeField(
                label: '开始时间',
                anchorDate: startAnchor,
                value: _startEdit,
                enabled: !readOnly,
                glassStyle: true,
                onChanged: (v) => setState(() => _startEdit = v),
              ),
              const SizedBox(height: 14),
              HomeHistoryTimeField(
                label: '结束时间',
                anchorDate: endAnchor,
                value: _endEdit,
                enabled: !readOnly,
                glassStyle: true,
                onChanged: (v) => setState(() => _endEdit = v),
              ),
              if (!readOnly && _endEdit != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _endEdit = null),
                    style: TextButton.styleFrom(
                      foregroundColor: glassLabel,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('清除结束时间'),
                  ),
                ),
            ] else ...[
              HomeHistoryTimeField(
                label: '结束时间',
                anchorDate: endAnchor,
                value: _endEdit,
                enabled: !readOnly,
                glassStyle: true,
                onChanged: (v) => setState(() => _endEdit = v),
              ),
            ],
            if (n > 1) ...[
              const SizedBox(height: 14),
              Text(
                '用量${unit.isNotEmpty ? '（$unit）' : ''}',
                style: TextStyle(fontSize: 13, color: glassLabel),
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: HomeEventNumberPicker(
                    controller: _usagePickerCtrl,
                    enabled: !readOnly,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _remarkCtrl,
              focusNode: _remarkFocusNode,
              readOnly: readOnly,
              style: TextStyle(color: glassText, fontSize: 15),
              cursorColor: scheme.primary,
              decoration: historyEditGlassInputDecoration(context, labelText: '备注'),
              textInputAction: TextInputAction.done,
              onTap: _onRemarkFocusChange,
              onChanged: readOnly ? null : keyboardInputBridgeController.updateDraft,
              onSubmitted: readOnly ? null : (_) => FocusScope.of(context).unfocus(),
              maxLines: 1,
            ),
            if (showStop) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _stoppingActive ? null : _stopActiveTiming,
                style: OutlinedButton.styleFrom(
                  foregroundColor: glassText,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(_stoppingActive ? '停止中…' : '停止'),
              ),
            ],
            if (!readOnly) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _deleting ? null : _confirmDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error.withValues(alpha: 0.9),
                  ),
                  child: Text(_deleting ? '删除中…' : '删除'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : _requestClose,
                    style: TextButton.styleFrom(
                      foregroundColor: glassText,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(_saving ? '保存中…' : '保存'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
