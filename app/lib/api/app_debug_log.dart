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

  static void wsTransport(String message) {
    if (!kDebugMode) return;
    debugPrint('[WsTransport] ${_ts()} $message');
  }

  static void homeWidget(String message) {
    if (!kDebugMode) return;
    debugPrint('[HomeWidget] ${_ts()} $message');
  }

  /// 商业功能 catalog / 资格 / 建单 / 邀请码 / 广告 / 支付宝。
  static void featureUnlock(String message) {
    if (!kDebugMode) return;
    debugPrint('[FeatureUnlock] ${_ts()} $message');
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

  /// 客户端使用上报（静默；失败仅 Debug）。
  static void clientUsage(String message) {
    if (!kDebugMode) return;
    debugPrint('[ClientUsage] ${_ts()} $message');
  }

  /// 预测临近 pending 同步（离线提醒）。
  static void predictImminent(String message) {
    if (!kDebugMode) return;
    debugPrint('[PredictImminent] ${_ts()} $message');
  }

  /// 间隔预测：钟点亲和投票 / 直方图护栏（无 token、无全量历史）。
  static void predictInterval(String message) {
    if (!kDebugMode) return;
    debugPrint('[PredictInterval] ${_ts()} $message');
  }

  /// 进行中计时 ETA 同步（active-eta Redis）。
  static void predictActiveEta(String message) {
    if (!kDebugMode) return;
    debugPrint('[PredictActiveEta] ${_ts()} $message');
  }

  /// iOS Live Activity token 上报 / 深链。
  static void liveActivity(String message) {
    if (!kDebugMode) return;
    debugPrint('[LiveActivity] ${_ts()} $message');
  }

  /// 预约下次约定 GET/PUT。
  static void appointmentNext(String message) {
    if (!kDebugMode) return;
    debugPrint('[AppointmentNext] ${_ts()} $message');
  }

  /// 批量最近发生 latest-by-event。
  static void historyLatest(String message) {
    if (!kDebugMode) return;
    debugPrint('[HistoryLatest] ${_ts()} $message');
  }

  /// 历史突变后静默调度（锚点链 expect-batch / resume）。
  static void predictPostMutation(String message) {
    if (!kDebugMode) return;
    debugPrint('[PredictPostMutation] ${_ts()} $message');
  }

  /// 主壳满意度问卷 GET/POST（GET 失败静默）。
  static void survey(String message) {
    if (!kDebugMode) return;
    debugPrint('[Survey] ${_ts()} $message');
  }

  /// 小智音箱引导视频清单 / 播放。
  static void xiaozhiGuide(String message) {
    if (!kDebugMode) return;
    debugPrint('[XiaozhiGuide] ${_ts()} $message');
  }

  /// 预测 Pro 想法 list/submit/like。
  static void predictProIdea(String message) {
    if (!kDebugMode) return;
    debugPrint('[PredictProIdea] ${_ts()} $message');
  }

  /// 宝宝全家共享：出示码 / 扫码 / 相册识码 / 预览。
  static void babyShare(String message) {
    if (!kDebugMode) return;
    debugPrint('[BabyShare] ${_ts()} $message');
  }
}
