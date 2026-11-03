import Flutter
import UIKit
import UserNotifications

class SceneDelegate: FlutterSceneDelegate {
  /// UIScene 冷启：notificationResponse 常比 launchOptions.remoteNotification 更可靠。
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    UcgNotificationCenterProxy.install(reason: "sceneWillConnect")
    if let response = connectionOptions.notificationResponse {
      NSLog("[ucg_push] scene willConnect has notificationResponse")
      UcgPushTapInbox.noteUserInfo(
        response.notification.request.content.userInfo,
        source: "scene"
      )
    } else {
      NSLog("[ucg_push] scene willConnect no notificationResponse")
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    // 从后台点通知回前台：夺回 delegate，防止热点击静默。
    UcgNotificationCenterProxy.install(reason: "sceneDidBecomeActive")
    super.sceneDidBecomeActive(scene)
  }

  /// Live Activity / 小组件 pangbao:// 深链（不 dismiss LA，仅投递 bizType）。
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for ctx in URLContexts {
      if ctx.url.scheme?.lowercased() == "pangbao" {
        PredictLiveActivityBridge.noteOpenURL(ctx.url)
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
