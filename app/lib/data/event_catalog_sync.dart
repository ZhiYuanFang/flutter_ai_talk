import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import 'event_catalog_store.dart';
import 'event_definition.dart';

/// 从网关拉取事件目录并与本地缓存同步。
class EventCatalogSync {
  EventCatalogSync(this._api);

  final ApiClient _api;

  Future<List<EventDefinition>> fetchRemoteList() async {
    final data = await _api.getEnvelope('/device/history/api/event/options');
    if (data == null) return const [];
    final list = data['list'] as List<dynamic>? ?? const [];
    return parseEventOptionsList(list);
  }

  /// 拉取远端、对比本地；有变化则写盘并下载 logo。失败时返回 null（调用方保留旧状态）。
  Future<List<EventDefinition>?> refreshAndPersist() async {
    try {
      final remote = await fetchRemoteList();
      final local = await EventCatalogStore.loadFromDisk();
      if (catalogSnapshotsEqual(remote, local)) {
        return local;
      }
      final withLogos = await EventCatalogStore.applyLogoDownloads(remote);
      await EventCatalogStore.saveToDisk(withLogos);
      final keepPaths = withLogos
          .map((e) => e.localLogoPath)
          .whereType<String>()
          .toSet();
      await EventCatalogStore.pruneLogoFiles(keepPaths);
      return withLogos;
    } on ApiBusinessException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
