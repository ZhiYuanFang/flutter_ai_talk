import 'package:flutter/material.dart';

import '../data/event_catalog_tree.dart';
import '../data/event_catalog_usage_sort.dart';
import '../data/event_definition.dart';
import 'event_logo.dart';
import 'home_button_event_grid.dart'
    show
        kHomeEventButtonColumnGap,
        kHomeEventButtonColumnWidth,
        kHomeEventButtonRowHeight;
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

/// 方案 B：单 Bottom Sheet，内部 path 栈无限层级；选中叶子后 pop。
Future<EventDefinition?> showEventCatalogPickerSheet(
  BuildContext context, {
  required List<EventDefinition> catalog,
  required EventDefinition root,
  Map<String, int>? usageCounts,
  void Function(String message)? onToast,
}) {
  return showGlassAdaptiveBottomSheet<EventDefinition>(
    context: context,
    eventAccent: resolveEventColor(context, root),
    scrollable: false,
    bodyBuilder: (ctx) => _EventCatalogPickerSheet(
      catalog: catalog,
      initialPath: [root],
      usageCounts: usageCounts,
      onToast: onToast,
    ),
  );
}

class _EventCatalogPickerSheet extends StatefulWidget {
  const _EventCatalogPickerSheet({
    required this.catalog,
    required this.initialPath,
    this.usageCounts,
    this.onToast,
  });

  final List<EventDefinition> catalog;
  final List<EventDefinition> initialPath;
  final Map<String, int>? usageCounts;
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
    var items = childrenOf(widget.catalog, current.id);
    final counts = widget.usageCounts;
    if (counts != null) {
      items = sortEventsBySubtreeUsage(widget.catalog, items, counts);
    }
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
          child: Row(
            children: [
              if (_path.length > 1)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: glassText),
                  tooltip: '返回上一级',
                  onPressed: _onBack,
                )
              else
                const SizedBox(width: 8),
              EventLogo(
                definition: current,
                size: 32,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glassText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '暂无子项',
                style: TextStyle(fontSize: 14, color: glassLabel),
              ),
            ),
          )
        else
          SizedBox(
            height: kHomeEventButtonRowHeight + 14,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: kHomeEventButtonColumnGap),
              itemBuilder: (context, index) {
                final e = items[index];
                final folder = hasChildren(widget.catalog, e.id);
                return SizedBox(
                  width: kHomeEventButtonColumnWidth,
                  child: _CatalogPickerEventCell(
                    event: e,
                    isFolder: folder,
                    labelColor: glassText,
                    mutedColor: glassLabel,
                    onTap: () => _onItemTap(e),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CatalogPickerEventCell extends StatelessWidget {
  const _CatalogPickerEventCell({
    required this.event,
    required this.isFolder,
    required this.labelColor,
    required this.mutedColor,
    required this.onTap,
  });

  final EventDefinition event;
  final bool isFolder;
  final Color labelColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EventLogo(
              definition: event,
              size: 40,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 4),
            Text(
              event.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
            ),
            if (isFolder) ...[
              const SizedBox(height: 2),
              Icon(Icons.chevron_right, size: 16, color: mutedColor),
            ],
          ],
        ),
      ),
    );
  }
}
