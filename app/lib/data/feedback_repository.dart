import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import 'feedback_models.dart';

class FeedbackRepository {
  FeedbackRepository(this._api, {void Function(String message)? onToastError})
      : _onToastError = onToastError ?? ((_) {});

  final ApiClient _api;
  final void Function(String message) _onToastError;

  Future<List<FeedbackItem>> list() async {
    try {
      final data = await _api.getEnvelope('/device/app/api/feedback/list');
      return envelopeListOrEmpty(data)
          .whereType<Map>()
          .map((e) => FeedbackItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }

  Future<FeedbackItem?> submit(String question) async {
    try {
      final data = await _api.postJsonEnvelope(
        '/device/app/api/feedback/submit',
        {'question': question},
      );
      if (data != null) {
        return FeedbackItem.fromJson(data);
      }
      return null;
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }
}
