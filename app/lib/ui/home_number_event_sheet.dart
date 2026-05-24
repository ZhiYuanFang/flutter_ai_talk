import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/history_mapper.dart';

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

final _numberPickerValues = [
  for (var v = 5; v <= 500; v += 5) v,
];

/// number 事件：时刻 + Cupertino 滚轮用量 + 可选 remark。
Future<HomeNumberEventResult?> showHomeNumberEventSheet(
  BuildContext context,
  EventDefinition event,
) {
  return showModalBottomSheet<HomeNumberEventResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _HomeNumberEventSheet(event: event),
  );
}

class _HomeNumberEventSheet extends StatefulWidget {
  const _HomeNumberEventSheet({required this.event});

  final EventDefinition event;

  @override
  State<_HomeNumberEventSheet> createState() => _HomeNumberEventSheetState();
}

class _HomeNumberEventSheetState extends State<_HomeNumberEventSheet> {
  late DateTime _selectedTime;
  late FixedExtentScrollController _pickerCtrl;
  final _remarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTime = DateTime.now();
    _pickerCtrl = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _pickerCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final base = _selectedTime;
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(base.year, base.month, base.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    setState(() {
      _selectedTime = DateTime(d.year, d.month, d.day, base.hour, base.minute);
    });
  }

  Future<void> _pickTime() async {
    final base = _selectedTime;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (t == null || !mounted) return;
    setState(() {
      _selectedTime = DateTime(base.year, base.month, base.day, t.hour, t.minute);
    });
  }

  void _confirm() {
    final index = _pickerCtrl.hasClients ? _pickerCtrl.selectedItem : 0;
    final usage = _numberPickerValues[index.clamp(0, _numberPickerValues.length - 1)];
    Navigator.pop(
      context,
      HomeNumberEventResult(
        startTime: _selectedTime,
        eventNumber: usage,
        remark: _remarkCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.event.name,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(formatHistoryApiDateTime(_selectedTime).substring(0, 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(formatHistoryApiDateTime(_selectedTime).substring(11, 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: CupertinoPicker(
              scrollController: _pickerCtrl,
              itemExtent: 36,
              onSelectedItemChanged: (_) {},
              children: _numberPickerValues
                  .map((v) => Center(child: Text('$v')))
                  .toList(),
            ),
          ),
          TextField(
            controller: _remarkCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _confirm,
            child: const Text('确认记录'),
          ),
        ],
      ),
    );
  }
}
