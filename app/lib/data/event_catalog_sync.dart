import 'dart:async';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import 'event_catalog_store.dart';
import 'event_definition.dart';

/// 从网关拉取事件目录并与本地缓存同步。
class EventCatalogSync {
  EventCatalogSync(this._api);

  final ApiClient _api;

  Future<List<EventDefinition>> fetchRemoteList({
    String? deviceNo,
    bool withAuthorization = true,
  }) async {
    final withDevice = await _fetchOnce(deviceNo, withAuthorization: withAuthorization);
    if (withDevice.isNotEmpty) return withDevice;
    if (deviceNo != null && deviceNo.isNotEmpty) {
      return _fetchOnce(null, withAuthorization: withAuthorization);
    }
    return withDevice;
  }

  Future<List<EventDefinition>> _fetchOnce(
    String? deviceNo, {
    required bool withAuthorization,
  }) async {
    final query = (deviceNo != null && deviceNo.isNotEmpty)
        ? {'deviceNo': deviceNo}
        : null;
    final data = await _api.getEnvelope(
      '/device/history/api/event/options',
      query: query,
      withAuthorization: withAuthorization,
    );
    final list = envelopeListOrEmpty(data);
    return parseEventOptionsList(list);
  }

  /// 拉取远端、对比本地；有变化则写盘并下载 logo。失败或远端空列表时保留本地缓存。
  Future<List<EventDefinition>?> refreshAndPersist({
    String? deviceNo,
    bool withAuthorization = true,
  }) async {
    try {
      final remote = await fetchRemoteList(
        deviceNo: deviceNo,
        withAuthorization: withAuthorization,
      );
      final local = await EventCatalogStore.loadFromDisk();
      if (remote.isEmpty && local.isNotEmpty) {
        return local;
      }
      if (catalogSnapshotsEqual(remote, local)) {
        return local.isNotEmpty ? local : remote;
      }
      if (remote.isEmpty) {
        return local.isNotEmpty ? local : remote;
      }
      final merged = await EventCatalogStore.mergeLocalLogoPaths(remote, local);
      await EventCatalogStore.saveToDisk(merged);
      return merged;
    } on ApiBusinessException {
      final disk = await EventCatalogStore.loadFromDisk();
      return disk;
    } catch (_) {
      final disk = await EventCatalogStore.loadFromDisk();
      return disk;
    }
  }

}
