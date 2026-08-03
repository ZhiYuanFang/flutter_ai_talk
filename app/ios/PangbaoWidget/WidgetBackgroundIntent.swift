import AppIntents
import Foundation
import home_widget

/// 小组件「跳过」后台 Intent：唤醒 Dart interactivityCallback。
@available(iOS 17, *)
public struct WidgetBackgroundIntent: AppIntent {
  public static var title: LocalizedStringResource = "胖宝小组件后台"

  @Parameter(title: "Widget URI")
  public var url: URL?

  @Parameter(title: "AppGroup")
  public var appGroup: String?

  public init() {}

  public init(url: URL?, appGroup: String?) {
    self.url = url
    self.appGroup = appGroup
  }

  public func perform() async throws -> some IntentResult {
    let group = appGroup ?? "group.com.fzy.pangbao.widget"
    await HomeWidgetBackgroundWorker.run(url: url, appGroup: group)
    return .result()
  }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension WidgetBackgroundIntent: ForegroundContinuableIntent {}
