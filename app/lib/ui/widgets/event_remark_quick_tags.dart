import 'package:flutter/material.dart';

import '../../config/event_remark_memory_store.dart';

/// 备注快捷标签：按 [eventId] 加载最近备注，点击 [onSelect]。
class EventRemarkQuickTags extends StatefulWidget {
  const EventRemarkQuickTags({
    super.key,
    required this.eventId,
    required this.onSelect,
    this.padding = const EdgeInsets.only(top: 8),
  });

  final String eventId;
  final ValueChanged<String> onSelect;
  final EdgeInsetsGeometry padding;

  @override
  State<EventRemarkQuickTags> createState() => _EventRemarkQuickTagsState();
}

class _EventRemarkQuickTagsState extends State<EventRemarkQuickTags> {
  List<String> _remarks = const [];
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRemarks();
  }

  @override
  void didUpdateWidget(covariant EventRemarkQuickTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _loadRemarks();
    }
  }

  Future<void> _loadRemarks() async {
    final remarks = await EventRemarkMemoryStore.load(widget.eventId);
    if (!mounted) return;
    setState(() {
      _remarks = remarks;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _remarks.isEmpty) return const SizedBox.shrink();

    final fill = Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    return Padding(
      padding: widget.padding,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (final remark in _remarks)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onSelect(remark),
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      remark,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
