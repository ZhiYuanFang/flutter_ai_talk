import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:pangbao_app/home_widget/home_widget_payload.dart';

/// Debug 白名单日志（与 [ApiHttpLog] 并列；logcat 脚本按 tag 过滤）。
abstract final class AppDebugLog {
  static String _ts() => HomeWidgetRowPayload.isoUtc(DateTime.now());

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

  static void ucgCompose(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgCompose] ${_ts()} $message');
  }

  static void ucgPlay(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgPlay] ${_ts()} $message');
  }

  static void ucgUnread(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgUnread] ${_ts()} $message');
  }

  static void ucgPush(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgPush] ${_ts()} $message');
  }

  static void ucgShare(String message) {
    if (!kDebugMode) return;
    debugPrint('[UcgShare] ${_ts()} $message');
  }

  static void pangbaoClinic(String message) {
    if (!kDebugMode) return;
    debugPrint('[PangbaoClinic] ${_ts()} $message');
  }

  static void wsTransport(String message) {
    if (!kDebugMode) return;
    debugPrint('[WsTransport] ${_ts()} $message');
  }

  static void homeWidget(String message) {
    if (!kDebugMode) return;
    debugPrint('[HomeWidget] ${_ts()} $message');
  }

  /// 护理留意日缓存拉取 / 忽略 / 飞轮反馈。
  static void careAlert(String message) {
    if (!kDebugMode) return;
    debugPrint('[CareAlert] ${_ts()} $message');
  }

  /// Cash VIP 商品 / 状态 / 建单 / 支付验单。
  static void cashVip(String message) {
    if (!kDebugMode) return;
    debugPrint('[CashVip] ${_ts()} $message');
  }

  /// 横屏 KWS 模型下载 / 解压 / 完整性。
  static void landscapeKws(String message) {
    if (!kDebugMode) return;
    debugPrint('[LandscapeKws] ${_ts()} $message');
  }

  /// 横屏语音：chat WS 就绪 / 唤醒开听各步。
  static void landscapeVoice(String message) {
    if (!kDebugMode) return;
    debugPrint('[LandscapeVoice] ${_ts()} $message');
  }
}
