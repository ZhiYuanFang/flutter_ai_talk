import 'package:flutter/material.dart';

import '../theme/app_visual_tokens.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import 'event_logo.dart';

/// 按钮模式单行根事件列表。
List<EventDefinition> buttonGridRowEvents(List<EventDefinition> catalog) {
  var valid = buttonGridRootEvents(catalog);
  // 目录有数据但层级过滤为空时仍展示（冷启动旧缓存兼容）。
  if (valid.isEmpty && catalog.isNotEmpty) {
    valid = catalog;
  }
  return valid;
}

/// 单行事件按钮高度（logo + 名称）。
const kHomeEventButtonRowHeight = 68.0;

const kHomeEventButtonColumnWidth = 72.0;

const kHomeEventButtonColumnGap = 4.0;

/// 单行网格内容区高度（不含外层 padding）。
const kHomeEventButtonGridHeight = kHomeEventButtonRowHeight;

/// 按钮模式底部输入区推荐高度（与语音球 220 解耦）。
const kHomeButtonInputPanelHeight = kHomeEventButtonGridHeight + 8;

/// 按钮模式：单行横向滚动，无面板/单元格底色。
class HomeButtonEventGrid extends StatelessWidget {
  const HomeButtonEventGrid({
    super.key,
    required this.catalog,
    required this.onEventTap,
  });

  final List<EventDefinition> catalog;
  final ValueChanged<EventDefinition> onEventTap;

  @override
  Widget build(BuildContext context) {
    final events = buttonGridRowEvents(catalog);
    if (events.isEmpty) {
      return SizedBox(
        height: kHomeEventButtonGridHeight,
        child: Center(
          child: Text(
            '暂无可用事件按钮',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return SizedBox(
      height: kHomeEventButtonGridHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: kHomeEventButtonColumnGap),
        itemBuilder: (context, index) {
          final event = events[index];
          return SizedBox(
            width: kHomeEventButtonColumnWidth,
            height: kHomeEventButtonRowHeight,
            child: _EventButtonCell(
              event: event,
              onTap: () => onEventTap(event),
            ),
          );
        },
      ),
    );
  }
}

class _EventButtonCell extends StatelessWidget {
  const _EventButtonCell({
    required this.event,
    required this.onTap,
  });

  final EventDefinition event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final labelColor = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
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
          ],
        ),
      ),
    );
  }
}
