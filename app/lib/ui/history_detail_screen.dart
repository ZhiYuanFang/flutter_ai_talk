import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/models.dart';
import '../providers/repositories.dart';

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

  DateTime _startEdit = DateTime.now();
  DateTime? _endEdit;

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController();
    _usageCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(feedRepositoryProvider);
    final r = await repo.getRecord(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = r;
      _loading = false;
      if (r != null) {
        final p = r.rawPayload;
        _remarkCtrl.text = (p['remark'] as String?) ?? '';
        _startEdit = parseHistoryInstant(p['startTime']) ?? r.createdAt;
        _endEdit = parseHistoryInstant(p['endTime']);
        final n = historyPayloadInt(p, 'eventNumber');
        if (n > 1) {
          _usageCtrl.text = '${historyPayloadInt(p, 'eventNumber')}';
        }
        if ((n == 1 || n > 1) && _endEdit == null) {
          _endEdit = _startEdit;
        }
      }
    });
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    _usageCtrl.dispose();
    super.dispose();
  }

  /// 先调 **时分**（保留 [base] 的年月日）；符合「优先改分、其次改时、日期单独改」。
  Future<DateTime?> _pickTimeKeepingDate(DateTime base) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      // 数字输入便于直接改「分」，再改「时」；与「优先分、其次时」一致。
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (t == null || !mounted) return null;
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  /// 只调 **日期**（保留 [base] 的时分）。
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

  Widget _timeTile(
    String label,
    DateTime? value,
    DateTime dateFallback,
    void Function(DateTime) onPickTimeOrDate,
    {VoidCallback? onClear}
  ) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史详情'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop(false)),
        actions: [
          if (!_loading && _record != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _confirmDelete,
            ),
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
                    Text('事件名', style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      _record!.eventName.isEmpty ? '未知事件' : _record!.eventName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '创建时间：${_record!.createdAt.toLocal()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
                        children: historyLineSpans(
                          _record!,
                          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
                        ),
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
                ),
    );
  }
}
