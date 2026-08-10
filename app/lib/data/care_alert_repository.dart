import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'prediction_care_alert.dart';

/// 护理留意日缓存 API（Go 编排）；失败返回 null / false，不 Toast。
class CareAlertRepository {
  CareAlertRepository(this._api);

  final ApiClient _api;

  /// GET 日列表；首次生成可能较久，超时 90s。
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
      return null;
    } on ApiHttpException catch (e) {
      AppDebugLog.careAlert('daily http err=${e.statusCode}');
      return null;
    } catch (e) {
      AppDebugLog.careAlert('daily err=$e');
      return null;
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

  /// 固定意图飞轮：ignore | follow_up（无 NLP 文本）。
  Future<bool> postFeedback({
    required String deviceNo,
    required String suggestionId,
    required String intent,
  }) async {
    final dn = deviceNo.trim();
    final id = suggestionId.trim();
    final intentNorm = intent.trim();
    if (dn.isEmpty || id.isEmpty) return false;
    if (intentNorm != 'ignore' && intentNorm != 'follow_up') return false;
    try {
      await _api.postJsonEnvelope(
        '/device/api/care-alert/feedback',
        {
          'deviceNo': dn,
          'suggestionId': id,
          'intent': intentNorm,
        },
      );
      AppDebugLog.careAlert('feedback ok intent=$intentNorm idLen=${id.length}');
      return true;
    } catch (e) {
      AppDebugLog.careAlert('feedback err=$e');
      return false;
    }
  }
}
