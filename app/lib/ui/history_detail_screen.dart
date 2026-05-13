import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  late final TextEditingController _eventCtrl;
  late final TextEditingController _actionCtrl;
  HistoryRecord? _record;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _eventCtrl = TextEditingController();
    _actionCtrl = TextEditingController();
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
        _eventCtrl.text = r.eventName;
        _actionCtrl.text = r.action;
      }
    });
  }

  @override
  void dispose() {
    _eventCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(feedRepositoryProvider);
    await repo.updateHistoryRecord(
      widget.recordId,
      eventName: _eventCtrl.text.trim(),
      action: _actionCtrl.text.trim(),
    );
    if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史详情'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop(false)),
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
                    Text('创建时间：${_record!.createdAt.toLocal()}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _eventCtrl,
                            decoration: const InputDecoration(
                              labelText: '事件名',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '事件名不能为空';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _actionCtrl,
                            decoration: const InputDecoration(
                              labelText: '动作',
                              border: OutlineInputBorder(),
                            ),
                            minLines: 2,
                            maxLines: 5,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '动作不能为空';
                              return null;
                            },
                          ),
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
