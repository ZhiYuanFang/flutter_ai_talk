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

  /// 记录一次系统通知点击。
  static func noteUserInfo(_ userInfo: [AnyHashable: Any], source: String) {
    let keys = userInfo.keys.map { "\($0)" }.sorted().joined(separator: ",")
    NSLog("[ucg_push] tap in source=%@ keys=%@", source, keys)
    let biz = extractBizType(userInfo)
    NSLog("[ucg_push] tap out source=%@ bizType=%@", source, biz ?? "nil")
    if let biz = biz, !biz.isEmpty {
      if dartListening, let channel = channel {
        // Dart 已监听：热投递且不留 pending，避免挂起后误用。
        channel.invokeMethod("onNotificationTap", arguments: biz)
        pendingBizType = nil
        pendingConfirmedMissingBiz = false
      } else {
        pendingBizType = biz
        pendingConfirmedMissingBiz = false
        channel?.invokeMethod("onNotificationTap", arguments: biz)
      }
    } else if dartListening, let channel = channel {
      channel.invokeMethod("onNotificationTap", arguments: ["__confirmedPushTap": true])
      pendingBizType = nil
      pendingConfirmedMissingBiz = false
    } else {
      pendingBizType = nil
      pendingConfirmedMissingBiz = true
      channel?.invokeMethod("onNotificationTap", arguments: ["__confirmedPushTap": true])
    }
  }

  /// Dart 声明可收后：补发仍暂存的点击（不清除，留给紧随的 getInitial）。
  static func onDartListening() {
    dartListening = true
    guard let channel = channel else { return }
    if let biz = pendingBizType, !biz.isEmpty {
      NSLog("[ucg_push] dartListening flush bizType=%@", biz)
      channel.invokeMethod("onNotificationTap", arguments: biz)
    } else if pendingConfirmedMissingBiz {
      NSLog("[ucg_push] dartListening flush confirmedMissingBiz")
      channel.invokeMethod("onNotificationTap", arguments: ["__confirmedPushTap": true])
    }
  }

  /// Dart getInitial：取出并清空 pending。
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
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ucgPushChannel: FlutterMethodChannel?
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
    UNUserNotificationCenter.current().delegate = self
    if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      UcgPushTapInbox.noteUserInfo(remote, source: "launchOptions")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
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
        // Dart handler 已绑定，之后热点击可直接 invoke 且不留 stale pending。
        UcgPushTapInbox.onDartListening()
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
        // 只读授权态：granted / denied / notDetermined
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
  }

  /// 前台也展示横幅；点击仍走 didReceive，不在到达时跳转。
  override func userNotificationCenter(
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

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    NSLog("[ucg_push] didReceive action=%@", response.actionIdentifier)
    UcgPushTapInbox.noteUserInfo(
      response.notification.request.content.userInfo,
      source: "didReceive"
    )
    completionHandler()
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
