import ActivityKit
import Foundation
import Flutter
import UIKit

/// 主 App 侧 Live Activity：尽早监听统一 Attributes 的 Push-to-Start / activity token。
/// 唤醒窗内由原生免鉴权 register；token 另经 MethodChannel 可选投递 Dart 补传。
/// MUST NOT 在此调用 Activity.request（仅等服务端推送起停）。
/// MUST NOT 再为 update 做 ContentState ack 回执（改由 App 打开时鉴权 clear）。
enum PredictLiveActivityBridge {
  static let channelName = "com.fzy.pangbao/live_activity"
  /// 强引用：Native→Dart invoke 依赖实例；weak + 局部 let 会被 ARC 回收。
  static var channel: FlutterMethodChannel?
  /// Dart 已 setMethodCallHandler 并声明可收 token。
  private static var dartListening = false
  private static var started = false
  /// 本进程经 channel 成功投递的 push_to_start 次数（排障用）。
  private static var pushToStartDeliverCount: Int = 0
  /// 已为某 activity 挂上 pushTokenUpdates 的稳定键。
  private static var observedActivityKeys = Set<String>()
  /// channel / Dart 未就绪时的进程内 pending（仅 token）。
  private static var pending: [[String: Any]] = []
  private static let pendingLock = NSLock()
  private static let maxPending = 32

  static func startObservingEarly() {
    startIfNeeded()
  }

  static func startIfNeeded() {
    guard !started else { return }
    started = true
    beginObserving()
    NSLog("[live_activity] bridge started")
  }

  static func onDartListening() {
    dartListening = true
    NSLog("[live_activity] dartListening=1")
    flushPending()
  }

  static func pauseDartListening() {
    dartListening = false
    NSLog("[live_activity] dartListening=0")
  }

  static func restartListening() {
    observedActivityKeys.removeAll()
    started = false
    startIfNeeded()
    onDartListening()
    NSLog("[live_activity] bridge restarted")
  }

  static func systemStatus() -> [String: Any] {
    let iosVer = UIDevice.current.systemVersion
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
        "pushToStartDeliverCount": pushToStartDeliverCount,
        "iosVersion": iosVer,
      ]
    }
    return [
      "areActivitiesEnabled": false,
      "pushToStartSupported": false,
      "pushToStartDeliverCount": pushToStartDeliverCount,
      "iosVersion": iosVer,
    ]
  }

  /// 本机是否仍有可展示的统一列表 Live Activity（供 Dart 决定是否 clear 服务端 activity token）。
  static func hasActiveUnifiedLiveActivity() -> Bool {
    if #available(iOS 16.2, *) {
      return Activity<BabyLiveActivityAttributes>.activities.contains { activity in
        switch activity.activityState {
        case .active, .stale:
          return true
        default:
          return false
        }
      }
    }
    return false
  }

  private static func beginObserving() {
    // 统一单 Attributes；不再分 imminent/timing 双轨观察
    if #available(iOS 17.2, *) {
      observePushToStart(type: BabyLiveActivityAttributes.self)
    }
    if #available(iOS 16.2, *) {
      observeActivityTokens(type: BabyLiveActivityAttributes.self)
    }
  }

  @available(iOS 17.2, *)
  private static func observePushToStart<A: ActivityAttributes>(type: A.Type) {
    Task {
      for await tokenData in Activity<A>.pushToStartTokenUpdates {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        deliver([
          "tokenKind": "push_to_start",
          "token": token,
        ])
      }
    }
  }

  @available(iOS 16.2, *)
  private static func observeActivityTokens(type: BabyLiveActivityAttributes.Type) {
    for activity in Activity<BabyLiveActivityAttributes>.activities {
      attachActivityObservers(activity: activity)
    }
    Task {
      for await activity in Activity<BabyLiveActivityAttributes>.activityUpdates {
        attachActivityObservers(activity: activity)
      }
    }
  }

  @available(iOS 16.2, *)
  private static func attachActivityObservers(
    activity: Activity<BabyLiveActivityAttributes>
  ) {
    // 稳定键：系统 activity.id（统一单轨，无 attributesKind）
    let key = activity.id
    if observedActivityKeys.contains(key) {
      return
    }
    observedActivityKeys.insert(key)

    Task {
      for await tokenData in activity.pushTokenUpdates {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        deliver([
          "tokenKind": "activity",
          "token": token,
        ])
      }
    }
  }

  private static func deliver(_ args: [String: Any]) {
    LiveActivityNativeRegister.registerIfPossible(args)
    guard let channel = channel, dartListening else {
      enqueuePending(args)
      let reason = channel == nil ? "no_channel" : "dart_not_listening"
      NSLog(
        "[live_activity] deliver queued reason=%@ kind=%@",
        reason,
        (args["tokenKind"] as? String) ?? ""
      )
      return
    }
    invokeDeliver(channel: channel, args: args)
  }

  private static func invokeDeliver(channel: FlutterMethodChannel, args: [String: Any]) {
    let kind = (args["tokenKind"] as? String)?.lowercased() ?? ""
    DispatchQueue.main.async {
      channel.invokeMethod("onLiveActivityToken", arguments: args)
      if kind == "push_to_start" {
        pushToStartDeliverCount += 1
        NSLog(
          "[live_activity] deliver push_to_start count=%d",
          pushToStartDeliverCount
        )
      }
    }
  }

  private static func enqueuePending(_ args: [String: Any]) {
    let identity = pendingIdentity(args)
    pendingLock.lock()
    defer { pendingLock.unlock() }
    if pending.contains(where: { pendingIdentity($0) == identity }) {
      return
    }
    if pending.count >= maxPending {
      pending.removeFirst()
    }
    pending.append(args)
  }

  private static func flushPending() {
    guard let channel = channel, dartListening else { return }
    pendingLock.lock()
    let batch = pending
    pending.removeAll()
    pendingLock.unlock()
    if batch.isEmpty { return }
    NSLog("[live_activity] flush pending count=%d", batch.count)
    for args in batch {
      invokeDeliver(channel: channel, args: args)
    }
  }

  /// 去重身份：tokenKind + token（无 attributesKind/activityId）。
  private static func pendingIdentity(_ args: [String: Any]) -> String {
    let kind = (args["tokenKind"] as? String) ?? ""
    let token = (args["token"] as? String) ?? ""
    return "\(kind)|\(token)"
  }

  /// 解析 pangbao://live-activity... 深链 → 投递 bizType（不 dismiss LA）。
  static func noteOpenURL(_ url: URL) {
    let host = (url.host ?? "").lowercased()
    let path = url.path.lowercased()
    let combined = "\(host)\(path)"
    // 统一 path 或旧 /imminent /timing 均进预测页族
    guard combined.contains("live-activity")
      || combined.contains("imminent")
      || combined.contains("timing")
    else { return }
    let biz = "predict_imminent"
    NSLog("[live_activity] openURL bizType=%@", biz)
    UcgPushTapInbox.pendingBizType = biz
    UcgPushTapInbox.pendingConfirmedMissingBiz = false
    UcgPushTapInbox.channel?.invokeMethod("onNotificationTap", arguments: biz)
  }
}
