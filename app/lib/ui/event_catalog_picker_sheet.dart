import 'package:flutter/material.dart';

import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../theme/app_theme_scope.dart';
import 'event_logo.dart';

/// 方案 B：单 Bottom Sheet，内部 path 栈无限层级；选中叶子后 pop。
Future<EventDefinition?> showEventCatalogPickerSheet(
  BuildContext context, {
  required List<EventDefinition> catalog,
  required EventDefinition root,
  void Function(String message)? onToast,
}) {
  return showModalBottomSheet<EventDefinition>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: themePrimaryBlend(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _EventCatalogPickerSheet(
      catalog: catalog,
      initialPath: [root],
      onToast: onToast,
    ),
  );
}

class _EventCatalogPickerSheet extends StatefulWidget {
  const _EventCatalogPickerSheet({
    required this.catalog,
    required this.initialPath,
    this.onToast,
  });

  final List<EventDefinition> catalog;
  final List<EventDefinition> initialPath;
  final void Function(String message)? onToast;

  @override
  State<_EventCatalogPickerSheet> createState() => _EventCatalogPickerSheetState();
}

class _EventCatalogPickerSheetState extends State<_EventCatalogPickerSheet> {
  late List<EventDefinition> _path;

  @override
  void initState() {
    super.initState();
    _path = List<EventDefinition>.from(widget.initialPath);
  }

  String get _title {
    if (_path.length == 1) return _path.first.name;
    return _path.map((e) => e.name).join(' › ');
  }

  void _onBack() {
    if (_path.length <= 1) return;
    setState(() => _path.removeLast());
  }

  void _onItemTap(EventDefinition item) {
    if (hasChildren(widget.catalog, item.id)) {
      setState(() => _path.add(item));
      return;
    }
    if (!item.hasValidEventType) {
      widget.onToast?.call('该事件不可记录');
      return;
    }
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final current = _path.last;
    final items = childrenOf(widget.catalog, current.id);
    final sheetH = MediaQuery.sizeOf(context).height * 2 / 3;

    return SizedBox(
      height: sheetH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
            child: Row(
              children: [
                if (_path.length > 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '返回上一级',
                    onPressed: _onBack,
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '暂无子项',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final e = items[index];
                      final folder = hasChildren(widget.catalog, e.id);
                      return ListTile(
                        leading: EventLogo(definition: e, size: 28),
                        title: Text(e.name),
                        trailing: folder ? const Icon(Icons.chevron_right) : null,
                        onTap: () => _onItemTap(e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
