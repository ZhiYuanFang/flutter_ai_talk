import ActivityKit
import Foundation
import Flutter
import UIKit

/// 主 App 侧 Live Activity：尽早监听 Push-to-Start / per-activity token。
/// 唤醒窗内由原生免鉴权 register；另经 MethodChannel 可选投递 Dart 补传。
/// MUST NOT 在此调用 Activity.request（仅等服务端推送起停）。
enum PredictLiveActivityBridge {
  static let channelName = "com.fzy.pangbao/live_activity"
  /// 强引用：Native→Dart invoke 依赖实例；weak + 局部 let 会被 ARC 回收（Dart→Native 仍通）。
  static var channel: FlutterMethodChannel?
  /// Dart 已 setMethodCallHandler 并声明可收 token（对齐 UcgPushTapInbox.dartListening）。
  private static var dartListening = false
  private static var started = false
  /// 本进程经 channel 成功投递的 push_to_start 次数（排障用，不含 token）。
  private static var pushToStartDeliverCount: Int = 0
  /// 已为某 activity 挂上 pushTokenUpdates 的稳定键（防补扫与 updates 双订）。
  private static var observedActivityKeys = Set<String>()
  /// channel / Dart 未就绪时的进程内 pending（去重，不含落盘）。
  private static var pending: [[String: Any]] = []
  private static let pendingLock = NSLock()
  private static let maxPending = 32

  /// 进程启动早期即可调用：不依赖 Flutter channel / 登录态。
  static func startObservingEarly() {
    startIfNeeded()
  }

  /// 确保观察已启动（幂等）。Dart `startListening` 与 early start 共用。
  static func startIfNeeded() {
    guard !started else { return }
    started = true
    beginObserving()
    NSLog("[live_activity] bridge started")
  }

  /// Dart 声明可收：标记 listening 并 flush inbox。
  static func onDartListening() {
    dartListening = true
    NSLog("[live_activity] dartListening=1")
    flushPending()
  }

  /// 登出 / stop：暂停投递给 Dart，观察继续，token 重回 inbox。
  static func pauseDartListening() {
    dartListening = false
    NSLog("[live_activity] dartListening=0")
  }

  /// 手动重试：允许再次订阅（可能与旧 Task 并存；上报靠 Dart 身份缓存幂等）。
  static func restartListening() {
    // 清空已订 activity 键，便于补扫当前 activities 再挂 token 流
    observedActivityKeys.removeAll()
    started = false
    startIfNeeded()
    onDartListening()
    NSLog("[live_activity] bridge restarted")
  }

  /// 系统是否允许 Live Activities、是否支持 Push-to-Start、PTS deliver 计数。
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
    // B：先补扫已在跑的 LA，再订后续 activityUpdates
    for activity in Activity<A>.activities {
      attachPushTokenObserver(activity: activity, kind: kind, activityId: activityId)
    }
    Task {
      for await activity in Activity<A>.activityUpdates {
        attachPushTokenObserver(activity: activity, kind: kind, activityId: activityId)
      }
    }
  }

  @available(iOS 16.2, *)
  private static func attachPushTokenObserver<A: ActivityAttributes>(
    activity: Activity<A>,
    kind: String,
    activityId: @escaping (Activity<A>) -> String
  ) {
    let id = activityId(activity).trimmingCharacters(in: .whitespacesAndNewlines)
    // 稳定键：attributesKind + 系统 activity.id（比业务 activityId 更稳，避免空 id 漏订）
    let key = "\(kind)|\(activity.id)"
    if observedActivityKeys.contains(key) {
      return
    }
    observedActivityKeys.insert(key)
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

  private static func deliver(_ args: [String: Any]) {
    // 主路径：原生免鉴权 POST，不依赖 Dart / 登录壳 / channel
    LiveActivityNativeRegister.registerIfPossible(args)
    // channel 未就绪或 Dart 未听：入队，勿永久丢弃（Dart 补传）
    guard let channel = channel, dartListening else {
      enqueuePending(args)
      let reason = channel == nil ? "no_channel" : "dart_not_listening"
      NSLog(
        "[live_activity] deliver queued reason=%@ kind=%@ attr=%@",
        reason,
        (args["tokenKind"] as? String) ?? "",
        (args["attributesKind"] as? String) ?? ""
      )
      return
    }
    invokeDeliver(channel: channel, args: args)
  }

  private static func invokeDeliver(channel: FlutterMethodChannel, args: [String: Any]) {
    let kind = (args["tokenKind"] as? String)?.lowercased() ?? ""
    DispatchQueue.main.async {
      channel.invokeMethod("onLiveActivityToken", arguments: args)
      // 仅成功投递给 Dart 后计数
      if kind == "push_to_start" {
        pushToStartDeliverCount += 1
        NSLog(
          "[live_activity] deliver push_to_start count=%d attr=%@",
          pushToStartDeliverCount,
          (args["attributesKind"] as? String) ?? ""
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

  /// 去重身份：不含日志打印 token 原文以外的用途。
  private static func pendingIdentity(_ args: [String: Any]) -> String {
    let kind = (args["tokenKind"] as? String) ?? ""
    let attr = (args["attributesKind"] as? String) ?? ""
    let aid = (args["activityId"] as? String) ?? ""
    let token = (args["token"] as? String) ?? ""
    return "\(kind)|\(attr)|\(aid)|\(token)"
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
