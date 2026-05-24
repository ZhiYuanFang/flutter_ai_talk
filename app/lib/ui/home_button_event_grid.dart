import 'package:flutter/material.dart';

import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import 'event_logo.dart';

/// 将按钮模式根节点对半拆成两行（前半 → 上行，后半 → 下行）。
(List<EventDefinition> row1, List<EventDefinition> row2) splitEventCatalogForButtonGrid(
  List<EventDefinition> catalog,
) {
  var valid = buttonGridRootEvents(catalog);
  // 目录有数据但层级过滤为空时仍展示（冷启动旧缓存兼容）。
  if (valid.isEmpty && catalog.isNotEmpty) {
    valid = catalog;
  }
  if (valid.isEmpty) return (const [], const []);
  final splitAt = (valid.length / 2).ceil();
  return (valid.sublist(0, splitAt), valid.sublist(splitAt));
}

/// 单行事件按钮高度（logo + 名称）。
const kHomeEventButtonRowHeight = 68.0;

const kHomeEventButtonRowGap = 4.0;

const kHomeEventButtonColumnWidth = 72.0;

const kHomeEventButtonColumnGap = 8.0;

/// 两行网格内容区高度（不含外层 padding）。
const kHomeEventButtonGridHeight = kHomeEventButtonRowHeight * 2 + kHomeEventButtonRowGap;

/// 按钮模式底部输入区推荐高度（与语音球 220 解耦）。
const kHomeButtonInputPanelHeight = kHomeEventButtonGridHeight + 16;

/// 按钮模式：两行作为一个整体横向滚动（每列上下各一个 cell）。
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
    final (row1, row2) = splitEventCatalogForButtonGrid(catalog);
    if (row1.isEmpty && row2.isEmpty) {
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

    final columnCount = row1.length > row2.length ? row1.length : row2.length;

    return SizedBox(
      height: kHomeEventButtonGridHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: columnCount,
        separatorBuilder: (_, __) => const SizedBox(width: kHomeEventButtonColumnGap),
        itemBuilder: (context, index) {
          return SizedBox(
            width: kHomeEventButtonColumnWidth,
            child: Column(
              children: [
                SizedBox(
                  height: kHomeEventButtonRowHeight,
                  child: index < row1.length
                      ? _EventButtonCell(
                          event: row1[index],
                          onTap: () => onEventTap(row1[index]),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: kHomeEventButtonRowGap),
                SizedBox(
                  height: kHomeEventButtonRowHeight,
                  child: index < row2.length
                      ? _EventButtonCell(
                          event: row2[index],
                          onTap: () => onEventTap(row2[index]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
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
    final scheme = Theme.of(context).colorScheme;
    final brand = resolveEventColor(context, event);
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
                    color: brand.computeLuminance() > 0.55 ? scheme.onSurface : brand,
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
