import ActivityKit
import Foundation
import Flutter
import UIKit

/// 主 App 侧 Live Activity：监听 Push-to-Start / per-activity token，经 MethodChannel 交给 Dart 上报。
/// MUST NOT 在此调用 Activity.request（仅等服务端推送起停）。
enum PredictLiveActivityBridge {
  static let channelName = "com.fzy.pangbao/live_activity"
  static weak var channel: FlutterMethodChannel?
  private static var started = false

  /// Dart 绑定 channel 后调用，开始监听两类 Attributes 的 token 流。
  static func startIfNeeded() {
    guard !started else { return }
    started = true
    beginObserving()
    NSLog("[live_activity] bridge started")
  }

  /// 手动重试：允许再次订阅 Push-to-Start（可能与旧 Task 并存，上报幂等）。
  static func restartListening() {
    started = false
    startIfNeeded()
    NSLog("[live_activity] bridge restarted")
  }

  /// 系统是否允许 Live Activities、是否支持 Push-to-Start。
  static func systemStatus() -> [String: Any] {
    if #available(iOS 16.2, *) {
      let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
      let pts: Bool
      if #available(iOS 17.2, *) {
        pts = true
      } else {
        pts = false
      }
      return [
        "areActivitiesEnabled": enabled,
        "pushToStartSupported": pts,
      ]
    }
    return [
      "areActivitiesEnabled": false,
      "pushToStartSupported": false,
    ]
  }

  private static func beginObserving() {
    if #available(iOS 17.2, *) {
      observePushToStart(kind: "imminent", type: PredictImminentAttributes.self)
      observePushToStart(kind: "timing", type: PredictTimingAttributes.self)
    }
    if #available(iOS 16.2, *) {
      observeActivityTokens(kind: "imminent", type: PredictImminentAttributes.self) { $0.attributes.activityId }
      observeActivityTokens(kind: "timing", type: PredictTimingAttributes.self) { $0.attributes.activityId }
    }
  }

  @available(iOS 17.2, *)
  private static func observePushToStart<A: ActivityAttributes>(
    kind: String,
    type: A.Type
  ) {
    Task {
      for await tokenData in Activity<A>.pushToStartTokenUpdates {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        deliver([
          "tokenKind": "push_to_start",
          "attributesKind": kind,
          "token": token,
        ])
      }
    }
  }

  @available(iOS 16.2, *)
  private static func observeActivityTokens<A: ActivityAttributes>(
    kind: String,
    type: A.Type,
    activityId: @escaping (Activity<A>) -> String
  ) {
    Task {
      for await activity in Activity<A>.activityUpdates {
        let id = activityId(activity).trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
          for await tokenData in activity.pushTokenUpdates {
            let token = tokenData.map { String(format: "%02x", $0) }.joined()
            var args: [String: Any] = [
              "tokenKind": "activity",
              "attributesKind": kind,
              "token": token,
            ]
            if !id.isEmpty {
              args["activityId"] = id
            }
            deliver(args)
          }
        }
      }
    }
  }

  private static func deliver(_ args: [String: Any]) {
    guard let channel = channel else {
      NSLog("[live_activity] deliver skip reason=no_channel")
      return
    }
    DispatchQueue.main.async {
      channel.invokeMethod("onLiveActivityToken", arguments: args)
    }
  }

  /// 解析 pangbao://live-activity/... 深链 → 投递 bizType（不 dismiss LA）。
  static func noteOpenURL(_ url: URL) {
    let host = (url.host ?? "").lowercased()
    let path = url.path.lowercased()
    let combined = "\(host)\(path)"
    var biz: String?
    if combined.contains("imminent") {
      biz = "predict_imminent"
    } else if combined.contains("timing") {
      // 计时点击同样进预测页族
      biz = "predict_imminent"
    }
    guard let biz = biz else { return }
    NSLog("[live_activity] openURL bizType=%@", biz)
    UcgPushTapInbox.pendingBizType = biz
    UcgPushTapInbox.pendingConfirmedMissingBiz = false
    UcgPushTapInbox.channel?.invokeMethod("onNotificationTap", arguments: biz)
  }
}
