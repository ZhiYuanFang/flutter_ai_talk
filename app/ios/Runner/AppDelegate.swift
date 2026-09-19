import Flutter
import UIKit
import UserNotifications
import home_widget

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ucgPushChannel: FlutterMethodChannel?
  private var cachedApnsToken: String?
  /// 冷启动点击：channel 或 Dart 监听尚未就绪时暂存 userInfo。
  private var pendingTapUserInfo: [String: Any]?

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
      pendingTapUserInfo = flutterTapArgs(remote)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    ucgPushChannel = FlutterMethodChannel(name: "com.fzy.pangbao/ucg_push", binaryMessenger: messenger)
    ucgPushChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "AppDelegate released", details: nil))
        return
      }
      switch call.method {
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
        let pending = self.pendingTapUserInfo
        self.pendingTapUserInfo = nil
        result(pending)
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
    deliverNotificationTap(response.notification.request.content.userInfo)
    completionHandler()
  }

  private func deliverNotificationTap(_ userInfo: [AnyHashable: Any]) {
    let args = flutterTapArgs(userInfo)
    pendingTapUserInfo = args
    ucgPushChannel?.invokeMethod("onNotificationTap", arguments: args)
  }

  /// 只保留字符串字段，保证 MethodChannel 可编码；bizType 在根上。
  private func flutterTapArgs(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (key, value) in userInfo {
      let name = "\(key)"
      if name == "aps" { continue }
      if let text = value as? String {
        out[name] = text
      }
    }
    return out
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
