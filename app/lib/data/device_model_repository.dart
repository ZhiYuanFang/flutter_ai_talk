import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';

/// 账号设备型号上报：失败静默。
///
/// `PUT /device/app/api/user/device-model` body `{ deviceModel }`；须 Bearer。
class DeviceModelRepository {
  DeviceModelRepository(this._api);

  final ApiClient _api;

  static const _path = '/device/app/api/user/device-model';

  /// 上报展示用型号；空串不请求。
  Future<void> report(String deviceModel) async {
    final model = deviceModel.trim();
    if (model.isEmpty) {
      AppDebugLog.deviceModel('skip empty deviceModel');
      return;
    }
    try {
      await _api.putJsonEnvelope(_path, {
        'deviceModel': model,
      });
      AppDebugLog.deviceModel('ok modelLen=${model.length}');
    } on ApiBusinessException catch (e) {
      AppDebugLog.deviceModel('biz err=${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.deviceModel('http status=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.deviceModel('err=$e');
      rethrow;
    }
  }
}
