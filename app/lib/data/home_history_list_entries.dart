import 'history_line_format.dart';
import 'models.dart';

/// 按自然日分组的历史列表（用于主页 Sliver；日从新到旧，日内记录从新到旧）。
class HomeHistoryDayGroup {
  const HomeHistoryDayGroup({
    required this.dayLabel,
    required this.recordsNewestFirst,
  });

  final String dayLabel;
  final List<HistoryRecord> recordsNewestFirst;

  /// 日内时间升序（旧→新），用于正向列表：块顶为日期头、块底为当日最新。
  List<HistoryRecord> get recordsOldestFirst => recordsNewestFirst.reversed.toList();
}

/// 扁平条目（调试或备用）；主页滚动优先用 [buildHomeHistoryDayGroups]。
sealed class HomeHistoryListEntry {
  const HomeHistoryListEntry();
}

final class HomeHistoryRecordEntry extends HomeHistoryListEntry {
  const HomeHistoryRecordEntry({required this.record, required this.fromBottom});

  final HistoryRecord record;
  final int fromBottom;
}

final class HomeHistoryDayHeaderEntry extends HomeHistoryListEntry {
  const HomeHistoryDayHeaderEntry({required this.label});

  final String label;
}

/// [itemsAsc] 时间升序（旧→新），与主页 `_items` 一致。
List<HomeHistoryDayGroup> buildHomeHistoryDayGroups(
  List<HistoryRecord> itemsAsc, [
  DateTime? now,
]) {
  if (itemsAsc.isEmpty) return const [];

  final nowLocal = (now ?? DateTime.now()).toLocal();
  final byDay = <DateTime, List<HistoryRecord>>{};

  for (final r in itemsAsc) {
    final t = historyHomeDisplayInstant(r);
    final key = DateTime(t.year, t.month, t.day);
    byDay.putIfAbsent(key, () => []).add(r);
  }

  final dayKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  final groups = <HomeHistoryDayGroup>[];
  for (final day in dayKeys) {
    final list = byDay[day]!;
    list.sort((a, b) {
      final ta = historyHomeDisplayInstant(a);
      final tb = historyHomeDisplayInstant(b);
      return tb.compareTo(ta);
    });
    groups.add(
      HomeHistoryDayGroup(
        dayLabel: formatHistoryDaySectionLabel(day, nowLocal),
        recordsNewestFirst: list,
      ),
    );
  }
  return groups;
}

/// 视觉自下而上：记录（新→旧）+ 日期头，供扁平列表场景。
List<HomeHistoryListEntry> buildHomeHistoryListEntries(
  List<HistoryRecord> itemsAsc, [
  DateTime? now,
]) {
  final groups = buildHomeHistoryDayGroups(itemsAsc, now);
  final out = <HomeHistoryListEntry>[];
  var fromBottom = 0;
  for (final g in groups) {
    for (final r in g.recordsNewestFirst) {
      out.add(HomeHistoryRecordEntry(record: r, fromBottom: fromBottom++));
    }
    out.add(HomeHistoryDayHeaderEntry(label: g.dayLabel));
  }
  return out;
}
