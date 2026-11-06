import Flutter
import UIKit
import UserNotifications
import home_widget

/// APNs 点击暂存：AppDelegate / SceneDelegate 共用，对齐 Android pending bizType。
enum UcgPushTapInbox {
  /// 待 Dart 拉取的 bizType（非空）。
  static var pendingBizType: String?
  /// 已确认点击但载荷无 bizType，供 Dart Toast。
  static var pendingConfirmedMissingBiz = false
  static weak var channel: FlutterMethodChannel?
  /// Dart 已 setMethodCallHandler 并声明可收点击。
  static var dartListening = false

  /// 从 userInfo 根上抽出 bizType（字符串或可转字符串的标量）。
  static func extractBizType(_ userInfo: [AnyHashable: Any]) -> String? {
    for (key, value) in userInfo {
      let name = "\(key)"
      if name != "bizType" { continue }
      if let text = value as? String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
      if let num = value as? NSNumber {
        return num.stringValue
      }
    }
    return nil
  }

  /// 记录一次系统通知点击。始终写入 pending，便于 resume 补拉；有 channel 则同时热投递。
  static func noteUserInfo(_ userInfo: [AnyHashable: Any], source: String) {
    let keys = userInfo.keys.map { "\($0)" }.sorted().joined(separator: ",")
    NSLog("[ucg_push] tap in source=%@ keys=%@", source, keys)
    let biz = extractBizType(userInfo)
    NSLog("[ucg_push] tap out source=%@ bizType=%@ dartListening=%@",
          source, biz ?? "nil", dartListening ? "1" : "0")
    if let biz = biz, !biz.isEmpty {
      pendingBizType = biz
      pendingConfirmedMissingBiz = false
      deliverToDart(arguments: biz)
    } else {
      pendingBizType = nil
      pendingConfirmedMissingBiz = true
      deliverToDart(arguments: ["__confirmedPushTap": true])
    }
  }

  private static func deliverToDart(arguments: Any) {
    guard let channel = channel else {
      NSLog("[ucg_push] deliver skip reason=no_channel")
      return
    }
    DispatchQueue.main.async {
      channel.invokeMethod("onNotificationTap", arguments: arguments)
    }
  }

  /// Dart 声明可收后：补发仍暂存的点击（不清除，留给 getInitial / ack）。
  static func onDartListening() {
    dartListening = true
    NSLog("[ucg_push] dartListening=1")
    guard channel != nil else { return }
    if let biz = pendingBizType, !biz.isEmpty {
      NSLog("[ucg_push] dartListening flush bizType=%@", biz)
      deliverToDart(arguments: biz)
    } else if pendingConfirmedMissingBiz {
      NSLog("[ucg_push] dartListening flush confirmedMissingBiz")
      deliverToDart(arguments: ["__confirmedPushTap": true])
    }
  }

  /// Dart getInitial / resume 补拉：取出并清空 pending。
  static func takeInitialForDart() -> Any? {
    if let biz = pendingBizType, !biz.isEmpty {
      pendingBizType = nil
      pendingConfirmedMissingBiz = false
      return biz
    }
    if pendingConfirmedMissingBiz {
      pendingConfirmedMissingBiz = false
      return ["__confirmedPushTap": true]
    }
    return nil
  }

  /// Dart 已成功入箱后确认，避免 stale pending。
  static func ackDelivered() {
    pendingBizType = nil
    pendingConfirmedMissingBiz = false
  }
}

/// 独立通知代理：避免 Flutter/插件覆盖 AppDelegate 后热点击丢失。
final class UcgNotificationCenterProxy: NSObject, UNUserNotificationCenterDelegate {
  static let shared = UcgNotificationCenterProxy()

  static func install(reason: String) {
    UNUserNotificationCenter.current().delegate = shared
    NSLog("[ucg_push] notification delegate installed reason=%@", reason)
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    NSLog("[ucg_push] proxy didReceive action=%@", response.actionIdentifier)
    UcgPushTapInbox.noteUserInfo(
      response.notification.request.content.userInfo,
      source: "didReceive"
    )
    completionHandler()
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ucgPushChannel: FlutterMethodChannel?
  /// 强持有 LA channel，避免仅赋给 Bridge 后局部变量释放。
  private var liveActivityChannel: FlutterMethodChannel?
  private var cachedApnsToken: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 小组件后台 Intent 唤醒时注册插件
    if #available(iOS 17, *) {
      HomeWidgetBackgroundWorker.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
      }
    }
    UcgNotificationCenterProxy.install(reason: "didFinishLaunching")
    if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      UcgPushTapInbox.noteUserInfo(remote, source: "launchOptions")
    }
    // LA token 尽早观察：不依赖 Flutter/Dart startListening（后台唤醒窗口）
    PredictLiveActivityBridge.startObservingEarly()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    // 插件可能在启动后改写 delegate；每次前台夺回。
    UcgNotificationCenterProxy.install(reason: "didBecomeActive")
    super.applicationDidBecomeActive(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    UcgNotificationCenterProxy.install(reason: "engineReady")
    let messenger = engineBridge.applicationRegistrar.messenger()
    ucgPushChannel = FlutterMethodChannel(name: "com.fzy.pangbao/ucg_push", binaryMessenger: messenger)
    UcgPushTapInbox.channel = ucgPushChannel
    ucgPushChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "AppDelegate released", details: nil))
        return
      }
      switch call.method {
      case "readyForNotificationTaps":
        UcgPushTapInbox.onDartListening()
        result(nil)
      case "ackNotificationTap":
        UcgPushTapInbox.ackDelivered()
        result(nil)
      case "requestPermission":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
          DispatchQueue.main.async {
            if granted {
              UIApplication.shared.registerForRemoteNotifications()
            }
            result(granted)
          }
        }
      case "notificationStatus":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          DispatchQueue.main.async {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
              result("granted")
            case .denied:
              result("denied")
            case .notDetermined:
              result("notDetermined")
            @unknown default:
              result("denied")
            }
          }
        }
      case "getToken":
        let channel = (call.arguments as? [String: Any])?["channel"] as? String
        if channel == "apns", let token = self.cachedApnsToken, !token.isEmpty {
          result(token)
        } else {
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        }
      case "getInitialNotificationTap":
        result(UcgPushTapInbox.takeInitialForDart())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    // Live Activity token / 深链通道（Push to Start 监听；禁止本地 Activity.request）
    liveActivityChannel = FlutterMethodChannel(
      name: PredictLiveActivityBridge.channelName,
      binaryMessenger: messenger
    )
    PredictLiveActivityBridge.channel = liveActivityChannel
    // 引擎就绪后再确保一次观察（与 didFinishLaunching early start 幂等）
    PredictLiveActivityBridge.startObservingEarly()
    liveActivityChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "startListening":
        // 确保观察 + Dart 可收 + flush inbox
        PredictLiveActivityBridge.startIfNeeded()
        PredictLiveActivityBridge.onDartListening()
        result(nil)
      case "restartListening":
        PredictLiveActivityBridge.restartListening()
        result(nil)
      case "pauseDartListening":
        // 登出：停投递，原生观察与 inbox 保留
        PredictLiveActivityBridge.pauseDartListening()
        result(nil)
      case "getSystemStatus":
        result(PredictLiveActivityBridge.systemStatus())
      case "setRegisterContext":
        // Dart 登录后写入 wxId/deviceKey/apiBase，供唤醒窗原生 register
        let map = call.arguments as? [String: Any] ?? [:]
        let wxRaw = map["wxId"]
        let wxId: Int64
        if let n = wxRaw as? NSNumber {
          wxId = n.int64Value
        } else {
          wxId = Int64("\(wxRaw ?? "")") ?? 0
        }
        let deviceKey = (map["deviceKey"] as? String) ?? ""
        let apiBase = (map["apiBaseUrl"] as? String) ?? ""
        LiveActivityNativeRegister.setContext(
          wxId: wxId,
          deviceKey: deviceKey,
          apiBaseUrl: apiBase
        )
        result(nil)
      case "clearRegisterContext":
        // 登出：清缓存，避免旧 wxId 继续上报
        LiveActivityNativeRegister.clearContext()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 自定义 URL（Live Activity widgetURL / 小组件）。
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme?.lowercased() == "pangbao" {
      PredictLiveActivityBridge.noteOpenURL(url)
    }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    cachedApnsToken = token
    ucgPushChannel?.invokeMethod("onTokenRefresh", arguments: ["channel": "apns", "token": token])
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
