import '../api/app_debug_log.dart';
import '../config/env.dart';
import '../session/token_expiry.dart';
import '../ucg/push/ucg_push_registration_service.dart';
import 'live_activity_native.dart';

/// 将登录态 wxId + deviceKey + API 基址同步到 iOS 原生（唤醒窗免鉴权 register）。
Future<void> syncLiveActivityRegisterContext({
  required String? accessToken,
  required UcgPushRegistrationService pushRegistration,
}) async {
  final wxRaw = readJwtWxId(accessToken);
  final wxId = int.tryParse(wxRaw?.trim() ?? '') ?? 0;
  if (wxId <= 0) {
    await LiveActivityNative.clearRegisterContext();
    AppDebugLog.liveActivity('registerContext sync clear wxId invalid');
    return;
  }
  final deviceKey = await pushRegistration.deviceKey();
  await LiveActivityNative.setRegisterContext(
    wxId: wxId,
    deviceKey: deviceKey,
    apiBaseUrl: AppEnv.apiBaseUrl,
  );
}
