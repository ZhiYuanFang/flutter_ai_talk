import 'ucg_push_channel.dart';

/// Web / unsupported platform: no vendor push token.
class UcgPushNative {
  static Future<UcgPushChannel?> detectChannel() async => null;

  static Future<String?> fetchToken(UcgPushChannel channel) async => null;

  static Future<bool> requestNotificationPermission() async => false;

  static Stream<UcgPushTokenEvent> get tokenRefreshStream => const Stream.empty();
}
