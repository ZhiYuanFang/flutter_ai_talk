import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'client_usage_events.dart';

/// 客户端使用上报：失败静默丢弃，用户无感知。
///
/// 契约见 [ClientUsageEvents] 文件头注释；须登录 Bearer。
class ClientUsageRepository {
  ClientUsageRepository(this._api);

  final ApiClient _api;

  static const _path = '/device/app/api/client-usage/report';
  static const _maxLen = 128;

  /// 上报一条事件；非法字段直接跳过；网络/业务错误仅打 Debug 日志。
  Future<void> report(String featureId, String description) async {
    final id = _sanitize(featureId);
    final desc = _sanitize(description);
    if (id.isEmpty || desc.isEmpty) {
      AppDebugLog.clientUsage('skip empty featureId/description');
      return;
    }
    try {
      await _api.postJsonEnvelope(_path, {
        'featureId': id,
        'description': desc,
      });
      AppDebugLog.clientUsage('ok featureId=$id');
    } on ApiBusinessException catch (e) {
      AppDebugLog.clientUsage('biz err=${e.message} featureId=$id');
    } on ApiHttpException catch (e) {
      AppDebugLog.clientUsage('http status=${e.statusCode} featureId=$id');
    } catch (e) {
      AppDebugLog.clientUsage('err=$e featureId=$id');
    }
  }

  /// 使用字典事件上报。
  Future<void> reportEvent(ClientUsageEvent event) =>
      report(event.featureId, event.description);

  String _sanitize(String raw) {
    var t = raw.trim().replaceAll('|', '/');
    if (t.length > _maxLen) {
      t = t.substring(0, _maxLen);
    }
    return t;
  }
}
