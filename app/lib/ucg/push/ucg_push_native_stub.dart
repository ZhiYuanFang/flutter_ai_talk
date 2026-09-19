import 'ucg_push_channel.dart';

/// 系统通知授权态（与 mobile 对齐）。
enum OsNotificationAuth {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

/// Web / unsupported platform: no vendor push token.
class UcgPushNative {
  static Future<UcgPushChannel?> detectChannel() async => null;

  static Future<String?> fetchToken(UcgPushChannel channel) async => null;

  static Future<bool> requestNotificationPermission() async => false;

  /// Web 不支持系统通知。
  static Future<OsNotificationAuth> notificationAuthStatus() async =>
      OsNotificationAuth.unsupported;

  static Stream<UcgPushTokenEvent> get tokenRefreshStream => const Stream.empty();

  /// Web 没有系统通知点击。
  static Future<void> bindNotificationTaps() async {}
}
