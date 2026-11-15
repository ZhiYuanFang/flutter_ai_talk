import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../api/gateway_json.dart';
import 'predict_pro_idea_models.dart';

/// 预测 Pro 想法 App API（`/device/app/api/predict-pro-ideas/*`）。
class PredictProIdeaRepository {
  PredictProIdeaRepository(this._api);

  final ApiClient _api;

  static const _base = '/device/app/api/predict-pro-ideas';

  /// 公开想法列表（服务端已按新在前排序）。
  Future<List<PredictProIdeaItem>> list() async {
    try {
      final data = await _api.getEnvelope('$_base/list');
      final items = envelopeListOrEmpty(data)
          .whereType<Map>()
          .map((e) => PredictProIdeaItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id > 0 && e.text.trim().isNotEmpty)
          .toList();
      AppDebugLog.predictProIdea('list ok count=${items.length}');
      return items;
    } on ApiBusinessException catch (e) {
      AppDebugLog.predictProIdea('list business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.predictProIdea('list http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.predictProIdea('list err=$e');
      rethrow;
    }
  }

  /// 提交想法；成功返回新建项（若响应含字段）或仅 id。
  Future<PredictProIdeaItem?> submit(String text) async {
    try {
      final data = await _api.postJsonEnvelope('$_base/submit', {
        'text': text,
      });
      AppDebugLog.predictProIdea('submit ok');
      if (data == null) return null;
      final id = PredictProIdeaItem.fromJson(data).id;
      if (id <= 0) return null;
      return PredictProIdeaItem.fromJson(data);
    } on ApiBusinessException catch (e) {
      AppDebugLog.predictProIdea('submit business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.predictProIdea('submit http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.predictProIdea('submit err=$e');
      rethrow;
    }
  }

  Future<PredictProIdeaLikeResult> like(int id) async {
    return _likeAction('like', id);
  }

  Future<PredictProIdeaLikeResult> unlike(int id) async {
    return _likeAction('unlike', id);
  }

  Future<PredictProIdeaLikeResult> _likeAction(String action, int id) async {
    try {
      final data = await _api.postJsonEnvelope('$_base/$action', {
        'id': id,
      });
      AppDebugLog.predictProIdea('$action ok id=$id');
      if (data == null) {
        throw ApiBusinessException(-1, '点赞结果为空');
      }
      return PredictProIdeaLikeResult.fromJson(data);
    } on ApiBusinessException catch (e) {
      AppDebugLog.predictProIdea(
        '$action business err=${e.code} ${e.message}',
      );
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.predictProIdea('$action http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.predictProIdea('$action err=$e');
      rethrow;
    }
  }
}
