import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/event_branding.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/models.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/repositories.dart';
import 'event_name_header.dart';

enum _HistoryDetailMode { view, edit }

class HistoryDetailScreen extends ConsumerStatefulWidget {
  const HistoryDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _remarkCtrl;
  late final TextEditingController _usageCtrl;
  HistoryRecord? _record;
  var _loading = true;
  _HistoryDetailMode _mode = _HistoryDetailMode.view;

  DateTime _startEdit = DateTime.now();
  DateTime? _endEdit;
  Timer? _activeTimingTick;
  DateTime _tickNow = DateTime.now();
  var _stoppingActive = false;

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController();
    _usageCtrl = TextEditingController();
    _load();
  }

  String _displayEventName(HistoryRecord r) {
    final e = r.eventName.trim();
    return e.isEmpty ? '未知事件' : e;
  }

  void _applyRecordToForm(HistoryRecord r) {
    final p = r.rawPayload;
    _remarkCtrl.text = (p['remark'] as String?) ?? '';
    _startEdit = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    _endEdit = parseHistoryInstant(p['endTime']);
    final n = historyPayloadInt(p, 'eventNumber');
    if (n > 1) {
      _usageCtrl.text = '${historyPayloadInt(p, 'eventNumber')}';
    } else {
      _usageCtrl.clear();
    }
    if ((n == 1 || n > 1) && _endEdit == null) {
      _endEdit = _startEdit;
    }
  }

  Future<void> _load() async {
    final repo = ref.read(feedRepositoryProvider);
    final r = await repo.getRecord(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = r;
      _loading = false;
      _mode = _HistoryDetailMode.view;
      if (r != null) {
        _applyRecordToForm(r);
      }
    });
    _syncActiveTimingTick();
  }

  void _syncActiveTimingTick() {
    final r = _record;
    final active = r != null && isActiveTimingRecord(r);
    if (active && _mode == _HistoryDetailMode.view) {
      if (_activeTimingTick == null) {
        _activeTimingTick = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _tickNow = DateTime.now());
          final cur = _record;
          if (cur == null || !isActiveTimingRecord(cur) || _mode != _HistoryDetailMode.view) {
            _activeTimingTick?.cancel();
            _activeTimingTick = null;
          }
        });
      }
    } else {
      _activeTimingTick?.cancel();
      _activeTimingTick = null;
    }
  }

  Future<void> _stopActiveTiming() async {
    final r = _record;
    if (r == null || _stoppingActive || !isActiveTimingRecord(r)) return;
    setState(() => _stoppingActive = true);
    final p = r.rawPayload;
    final remark = (p['remark'] as String?) ?? '';
    final end = DateTime.now();
    final ok = await ref.read(feedRepositoryProvider).updateHistoryRecord(
          widget.recordId,
          remark: remark,
          startTime: activeTimingStartAt(r),
          endTime: end,
        );
    if (!mounted) return;
    setState(() => _stoppingActive = false);
    if (!ok) return;
    context.pop(true);
  }

  void _enterEdit() {
    setState(() => _mode = _HistoryDetailMode.edit);
    _syncActiveTimingTick();
  }

  void _cancelEdit() {
    final r = _record;
    if (r != null) {
      _applyRecordToForm(r);
    }
    setState(() => _mode = _HistoryDetailMode.view);
    _syncActiveTimingTick();
  }

  bool _isFormDirty() {
    final r = _record;
    if (r == null || _mode != _HistoryDetailMode.edit) return false;
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

    final endCompare = end ?? start ?? r.createdAt;
    if (_endEdit == null || _endEdit != endCompare) return true;
    if (n > 1) {
      final usage = historyPayloadInt(p, 'eventNumber');
      if (_usageCtrl.text != '$usage') return true;
    }
    return false;
  }

  Future<bool> _confirmDiscardEdits() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('放弃修改？'),
            content: const Text('未保存的修改将丢失。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续编辑')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('放弃')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleBack() async {
    if (_mode == _HistoryDetailMode.view) {
      context.pop(false);
      return;
    }
    if (_isFormDirty()) {
      final discard = await _confirmDiscardEdits();
      if (!discard || !mounted) return;
    }
    _cancelEdit();
  }

  @override
  void dispose() {
    _activeTimingTick?.cancel();
    _remarkCtrl.dispose();
    _usageCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickTimeKeepingDate(DateTime base) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (t == null || !mounted) return null;
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  Future<DateTime?> _pickDateKeepingTime(DateTime base) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(base.year, base.month, base.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return null;
    return DateTime(d.year, d.month, d.day, base.hour, base.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final r = _record;
    if (r == null) return;
    final n = historyPayloadInt(r.rawPayload, 'eventNumber');
    final repo = ref.read(feedRepositoryProvider);

    if (n == 0) {
      if (_endEdit != null && _endEdit!.isBefore(_startEdit)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('结束时间不能早于开始时间')));
        return;
      }
      final ok = await repo.updateHistoryRecord(
        widget.recordId,
        remark: _remarkCtrl.text.trim(),
        startTime: _startEdit,
        endTime: _endEdit,
        clearEndIfNull: true,
      );
      if (!mounted || !ok) return;
    } else if (n == 1) {
      if (_endEdit == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择结束时间')));
        return;
      }
      final ok = await repo.updateHistoryRecord(
        widget.recordId,
        remark: _remarkCtrl.text.trim(),
        startTime: _endEdit,
        endTime: _endEdit,
      );
      if (!mounted || !ok) return;
    } else {
      if (_endEdit == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择结束时间')));
        return;
      }
      final usage = int.tryParse(_usageCtrl.text.trim());
      if (usage == null || usage < 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用量须为正整数')));
        return;
      }
      final ok = await repo.updateHistoryRecord(
        widget.recordId,
        remark: _remarkCtrl.text.trim(),
        startTime: _endEdit,
        endTime: _endEdit,
        usageCount: usage,
      );
      if (!mounted || !ok) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    context.pop(true);
  }

  Future<void> _confirmDelete() async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除事件'),
            content: const Text('确定删除该条历史记录？此操作不可撤销。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
            ],
          ),
        ) ??
        false;
    if (!go || !mounted) return;
    final ok = await ref.read(feedRepositoryProvider).deleteHistoryRecord(widget.recordId);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
    context.pop(true);
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPreviewBody(HistoryRecord r) {
    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final remark = (p['remark'] as String?) ?? '';
    final end = parseHistoryInstant(p['endTime']);
    final start = parseHistoryInstant(p['startTime']);
    final endUnset = historyInstantUnset(end);
    final unit = (p['eventUnit'] as String?)?.trim() ?? '';
    final catalog = ref.watch(eventCatalogProvider);
    final eventDef = lookupEventForRecord(catalog, r);
    final children = <Widget>[
      EventNameHeader(name: _displayEventName(r), event: eventDef),
      const SizedBox(height: 12),
    ];

    if (n == 0) {
      final st = start ?? r.createdAt;
      children.add(_previewRow('开始时间', formatHistoryApiDateTime(st)));
      if (endUnset) {
        final elapsed = formatActiveTimerElapsed(_tickNow.difference(st));
        children.add(_previewRow('已计时长', elapsed));
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: _stoppingActive ? null : _stopActiveTiming,
                child: Text(_stoppingActive ? '停止中…' : '停止'),
              ),
            ),
          ),
        );
      } else if (end != null) {
        children.add(_previewRow('结束时间', formatHistoryApiDateTime(end)));
        children.add(_previewRow('用时', formatDurationForEvent0(st, end)));
      }
    } else if (n == 1) {
      final et = end ?? start ?? r.createdAt;
      children.add(_previewRow('结束时间', formatHistoryApiDateTime(et)));
    } else {
      final et = end ?? start ?? r.createdAt;
      children.add(_previewRow('结束时间', formatHistoryApiDateTime(et)));
      children.add(_previewRow('用量', '${historyPayloadInt(p, 'eventNumber')}${unit.isEmpty ? '' : unit}'));
    }

    children.add(_previewRow('备注', remark.trim()));
    return children;
  }

  Widget _timeTile(
    String label,
    DateTime? value,
    DateTime dateFallback,
    void Function(DateTime) onPickTimeOrDate, {
    VoidCallback? onClear,
  }) {
    final base = value ?? dateFallback;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(
        value != null ? formatHistoryApiDateTime(value) : '未设置',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null && value != null)
            IconButton(icon: const Icon(Icons.clear), onPressed: onClear, tooltip: '清除结束时间'),
          IconButton(
            icon: const Icon(Icons.schedule_outlined),
            tooltip: '改时分',
            onPressed: () async {
              final v = await _pickTimeKeepingDate(base);
              if (v != null && mounted) onPickTimeOrDate(v);
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: '改日期',
            onPressed: () async {
              final v = await _pickDateKeepingTime(base);
              if (v != null && mounted) onPickTimeOrDate(v);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _editFields(BuildContext context, HistoryRecord r) {
    final n = historyPayloadInt(r.rawPayload, 'eventNumber');
    final unit = (r.rawPayload['eventUnit'] as String?)?.trim() ?? '';
    final children = <Widget>[
      TextFormField(
        controller: _remarkCtrl,
        decoration: const InputDecoration(
          labelText: '备注',
          border: OutlineInputBorder(),
        ),
        minLines: 1,
        maxLines: 4,
      ),
      const SizedBox(height: 16),
    ];

    if (n == 0) {
      children.addAll([
        _timeTile('开始时间', _startEdit, _startEdit, (v) => setState(() => _startEdit = v)),
        _timeTile(
          '结束时间',
          _endEdit,
          _startEdit,
          (v) => setState(() => _endEdit = v),
          onClear: () => setState(() => _endEdit = null),
        ),
      ]);
    } else if (n == 1) {
      children.add(
        _timeTile('结束时间', _endEdit, _startEdit, (v) => setState(() => _endEdit = v)),
      );
    } else {
      children.addAll([
        _timeTile('结束时间', _endEdit, _startEdit, (v) => setState(() => _endEdit = v)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usageCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '用量${unit.isNotEmpty ? '（$unit）' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return '请输入用量';
            final u = int.tryParse(t);
            if (u == null || u < 1) return '须为正整数';
            return null;
          },
        ),
      ]);
    }

    return children;
  }

  String get _appBarTitle {
    final r = _record;
    if (r == null) return '历史详情';
    if (_mode == _HistoryDetailMode.edit) return '编辑';
    return _displayEventName(r);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mode == _HistoryDetailMode.view,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          actions: [
            if (!_loading && _record != null) ...[
              if (_mode == _HistoryDetailMode.view)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑',
                  onPressed: _enterEdit,
                )
              else
                TextButton(
                  onPressed: _handleBack,
                  child: const Text('取消'),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
                onPressed: _confirmDelete,
              ),
            ],
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _record == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('记录不存在：${widget.recordId}'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_mode == _HistoryDetailMode.view) ..._buildPreviewBody(_record!),
                      if (_mode == _HistoryDetailMode.edit) ...[
                        EventNameHeader(
                          name: _displayEventName(_record!),
                          event: lookupEventForRecord(
                            ref.watch(eventCatalogProvider),
                            _record!,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._editFields(context, _record!),
                              const SizedBox(height: 24),
                              FilledButton(onPressed: _save, child: const Text('保存')),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
