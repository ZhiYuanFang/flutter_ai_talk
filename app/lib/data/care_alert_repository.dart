import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'prediction_care_alert.dart';

/// 护理留意日缓存 API（Go 编排）；业务/HTTP 失败抛出，由调用方 Toast。
class CareAlertRepository {
  CareAlertRepository(this._api);

  final ApiClient _api;

  /// GET 日列表；首次生成可能较久，超时 90s。deviceNo 空返回 null。
  Future<List<CareAlertEventItem>?> fetchDaily({
    required String deviceNo,
  }) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return null;
    try {
      final data = await _api.getEnvelope(
        '/device/api/care-alert/daily',
        query: {'deviceNo': dn},
        timeout: const Duration(seconds: 90),
      );
      final items = parseCareAlertEventItems(data?['items']);
      AppDebugLog.careAlert(
        'daily ok deviceNoLen=${dn.length} count=${items.length} day=${data?['day']}',
      );
      return items;
    } on ApiBusinessException catch (e) {
      AppDebugLog.careAlert('daily business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.careAlert('daily http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.careAlert('daily err=$e');
      rethrow;
    }
  }

  /// 从当日缓存删除单条 suggestionId（DELETE + query，对齐现有 ApiClient）。
  Future<bool> deleteDailyItem({
    required String deviceNo,
    required String suggestionId,
  }) async {
    final dn = deviceNo.trim();
    final id = suggestionId.trim();
    if (dn.isEmpty || id.isEmpty) return false;
    try {
      await _api.deleteEnvelope(
        '/device/api/care-alert/daily/item',
        query: {'deviceNo': dn, 'suggestionId': id},
      );
      AppDebugLog.careAlert('delete item ok idLen=${id.length}');
      return true;
    } catch (e) {
      AppDebugLog.careAlert('delete item err=$e');
      return false;
    }
  }

  /// 已废弃：Care 无飞轮；ignore/follow_up 仅本地/日缓存 UI。
  @Deprecated('Care 无飞轮；勿再调用')
  Future<bool> postFeedback({
    required String deviceNo,
    required String suggestionId,
    required String intent,
  }) async {
    AppDebugLog.careAlert(
      'postFeedback noop intent=${intent.trim()} (Care flywheel retired)',
    );
    return true;
  }
}
