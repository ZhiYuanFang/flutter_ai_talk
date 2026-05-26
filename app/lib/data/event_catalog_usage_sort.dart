import 'event_catalog_tree.dart';
import 'event_definition.dart';

int _subtreeScore(
  String id,
  Map<String, int> counts,
  Map<String, int> cache,
  Map<String, List<EventDefinition>> childrenIndex,
) {
  final cached = cache[id];
  if (cached != null) return cached;

  var score = counts[id] ?? 0;
  for (final child in childrenIndex[id] ?? const []) {
    score += _subtreeScore(child.id, counts, cache, childrenIndex);
  }
  cache[id] = score;
  return score;
}

/// 按子树用量稳定降序；score 相同时保留 [nodes] 原序。
List<EventDefinition> sortEventsBySubtreeUsage(
  List<EventDefinition> catalog,
  List<EventDefinition> nodes,
  Map<String, int> counts,
) {
  if (nodes.length <= 1) return List<EventDefinition>.from(nodes);

  final childrenIndex = buildChildrenIndex(catalog);
  final scoreCache = <String, int>{};

  int score(String id) => _subtreeScore(id, counts, scoreCache, childrenIndex);

  final indexed = nodes.asMap().entries.toList();
  indexed.sort((a, b) {
    final diff = score(b.value.id) - score(a.value.id);
    if (diff != 0) return diff;
    return a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}
