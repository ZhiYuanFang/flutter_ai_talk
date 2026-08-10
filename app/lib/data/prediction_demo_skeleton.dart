import 'event_catalog_tree.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart';
import 'smart_prediction_rows.dart';

/// 未来 3 小时窗口（秒）。
const int kPredictionDemoSkeletonMaxOffsetSeconds = 3 * 60 * 60;

/// 冷态骨架行：全量无父根 + 稳定随机 nextAt（随 [mountNonce] 重抽）。
///
/// 不写 history、不写回忆种子；仅用于演示倒计时 UI。
List<SmartPredictionRow> buildPredictionDemoSkeletonRows({
  required List<EventDefinition> catalog,
  required DateTime mountNow,
  required int mountNonce,
}) {
  final roots = rootEvents(catalog);
  if (roots.isEmpty) return const [];

  final rows = <SmartPredictionRow>[];
  for (final root in roots) {
    final id = root.id.trim();
    if (id.isEmpty) continue;
    // 1..10800 秒，由 mountNonce + 根 id 稳定映射
    final offsetSec = _stableOffsetSeconds(mountNonce, id);
    final nextAt = mountNow.add(Duration(seconds: offsetSec));
    // 占位 lastAt：仅满足 EventNextPrediction 构造，不参与推演
    final lastAt = nextAt.subtract(const Duration(hours: 3));
    final name =
        root.name.trim().isEmpty ? '未命名事件' : root.name.trim();
    final hex = colorHexFromEvent(root);
    rows.add(
      SmartPredictionRow(
        eventId: id,
        eventName: name,
        colorHex: hex,
        forecastEnabled: true,
        prediction: EventNextPrediction(
          eventId: id,
          eventName: name,
          lastAt: lastAt,
          nextAt: nextAt,
          colorHex: hex,
          confidence: 0.5,
        ),
        chartPoints: const [],
      ),
    );
  }

  rows.sort((a, b) {
    final pa = a.prediction?.nextAt;
    final pb = b.prediction?.nextAt;
    if (pa != null && pb != null) return pa.compareTo(pb);
    return a.eventName.compareTo(b.eventName);
  });
  return rows;
}

/// 将 nonce 与 eventId 哈希到 [1, max] 秒偏移。
int _stableOffsetSeconds(int mountNonce, String eventId) {
  var h = mountNonce ^ 0x9e3779b9;
  for (final c in eventId.codeUnits) {
    h = 0x1fffffff & (h * 31 + c);
  }
  final span = kPredictionDemoSkeletonMaxOffsetSeconds;
  return 1 + (h.abs() % span);
}
