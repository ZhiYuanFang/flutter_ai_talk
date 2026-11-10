import 'event_definition.dart';

/// 目录 id 比较键（int/string 归一化）。
String catalogIdKey(String id) {
  final t = id.trim();
  if (t.isEmpty) return t;
  final n = int.tryParse(t);
  if (n != null) return n.toString();
  return t;
}

bool catalogIdsEqual(String a, String b) => catalogIdKey(a) == catalogIdKey(b);

/// 一级目录（无 parentId）。
bool isRootEvent(EventDefinition event) => event.parentId == null;

/// 目录是否含层级（至少一项有非空 parentId）。
bool catalogIsHierarchical(List<EventDefinition> catalog) {
  return catalog.any((e) => e.parentId != null);
}

/// 网格顶层：无 parentId，或 parent 不在 catalog 中。
bool isEffectiveRootEvent(List<EventDefinition> catalog, EventDefinition event) {
  final pid = event.parentId;
  if (pid == null) return true;
  return !catalog.any((p) => catalogIdsEqual(pid, p.id));
}

/// 父 id → 子列表（保持 catalog 顺序；orphan 不进入索引）。
Map<String, List<EventDefinition>> buildChildrenIndex(List<EventDefinition> catalog) {
  final index = <String, List<EventDefinition>>{};
  for (final e in catalog) {
    final pid = e.parentId;
    if (pid == null) continue;
    final parent = catalog.where((p) => catalogIdsEqual(pid, p.id)).firstOrNull;
    if (parent == null) continue;
    index.putIfAbsent(parent.id, () => []).add(e);
  }
  return index;
}

bool hasChildren(List<EventDefinition> catalog, String id) {
  for (final e in catalog) {
    final pid = e.parentId;
    if (pid != null && catalogIdsEqual(pid, id)) return true;
  }
  return false;
}

/// 目录项向上走到一级根 id（无父或父不在目录则停）。
String catalogRootIdFor(List<EventDefinition> catalog, String eventId) {
  var cur = eventId.trim();
  if (cur.isEmpty) return cur;
  final seen = <String>{};
  while (true) {
    if (seen.contains(cur)) return cur;
    seen.add(cur);
    EventDefinition? def;
    for (final e in catalog) {
      if (catalogIdsEqual(e.id, cur)) {
        def = e;
        break;
      }
    }
    final p = def?.parentId?.trim();
    if (p == null || p.isEmpty) return cur;
    cur = p;
  }
}

/// 根是否按合并预测：`mergePredict=true` 且目录确有直接子；叶子上的 true 不得单独发明并桶。
bool catalogRootMergePredict(String rootEventId, List<EventDefinition> catalog) {
  final root = rootEventId.trim();
  if (root.isEmpty) return false;
  EventDefinition? def;
  for (final e in catalog) {
    if (catalogIdsEqual(e.id, root)) {
      def = e;
      break;
    }
  }
  if (def == null || !def.mergePredict) return false;
  if (def.parentId != null) return false;
  return hasChildren(catalog, root);
}

/// API 顺序的根节点。
List<EventDefinition> rootEvents(List<EventDefinition> catalog) {
  return catalog.where(isRootEvent).toList();
}

List<EventDefinition> childrenOf(List<EventDefinition> catalog, String parentId) {
  return catalog
      .where((e) => e.parentId != null && catalogIdsEqual(e.parentId!, parentId))
      .toList();
}

/// 根 + 全部子孙 id（含根自身；保持 BFS 顺序，供 filter eventIds）。
List<String> catalogSubtreeEventIds(
  List<EventDefinition> catalog,
  String rootEventId,
) {
  final root = rootEventId.trim();
  if (root.isEmpty) return const [];
  final out = <String>[root];
  final queue = <String>[root];
  while (queue.isNotEmpty) {
    final pid = queue.removeAt(0);
    for (final c in childrenOf(catalog, pid)) {
      final id = c.id.trim();
      if (id.isEmpty) continue;
      if (out.any((e) => catalogIdsEqual(e, id))) continue;
      out.add(id);
      queue.add(id);
    }
  }
  return out;
}

/// 无子节点的事件；可选要求合法 [eventType]。
List<EventDefinition> leafEvents(
  List<EventDefinition> catalog, {
  bool requireValidEventType = false,
}) {
  return catalog.where((e) {
    if (hasChildren(catalog, e.id)) return false;
    if (requireValidEventType && !e.hasValidEventType) return false;
    return true;
  }).toList();
}

/// 旧版磁盘缓存可能缺少 eventType；有目录项时仍展示，待远端刷新后纠正。
List<EventDefinition> _recordableOrLegacyFlat(List<EventDefinition> catalog) {
  final typed = catalog.where((e) => e.hasValidEventType).toList();
  return typed.isNotEmpty ? typed : catalog;
}

/// 按钮模式网格：一级目录 / 文件夹；全扁平 legacy 时与变更前一致。
List<EventDefinition> buttonGridRootEvents(List<EventDefinition> catalog) {
  if (catalog.isEmpty) return const [];

  if (!catalogIsHierarchical(catalog)) {
    return _recordableOrLegacyFlat(catalog);
  }

  // 1. 显式一级：parentId 为空，且为文件夹或可记录叶子
  final topLevel = catalog
      .where(isRootEvent)
      .where((e) => hasChildren(catalog, e.id) || e.hasValidEventType)
      .toList();
  if (topLevel.isNotEmpty) return topLevel;

  // 2. 有效顶层（含 orphan：parent 不在 catalog）
  final effectiveTop = catalog
      .where((e) => isEffectiveRootEvent(catalog, e))
      .where((e) => hasChildren(catalog, e.id) || e.hasValidEventType)
      .toList();
  if (effectiveTop.isNotEmpty) return effectiveTop;

  // 3. 仍无：展示所有 parentId 为空项（通常为分类目录，即使暂未识别子项）
  final roots = rootEvents(catalog);
  if (roots.isNotEmpty) return roots;

  // 4. 可记录叶子；5. 旧缓存兜底
  return _recordableOrLegacyFlat(catalog);
}
