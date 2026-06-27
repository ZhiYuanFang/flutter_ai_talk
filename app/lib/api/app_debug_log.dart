import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Debug 白名单日志（与 [ApiHttpLog] 并列；logcat 脚本按 tag 过滤）。
abstract final class AppDebugLog {
  static String _ts() => DateTime.now().toIso8601String();

  static void ucgFeed(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgFeed] ${_ts()} $message');
  }

  static void ucgLocation(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgLocation] ${_ts()} $message');
  }

  static void ucgVideo(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgVideo] ${_ts()} $message');
  }
}
