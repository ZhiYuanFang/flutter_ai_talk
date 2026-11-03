import ActivityKit
import SwiftUI
import WidgetKit

/// Imminent / Timing Live Activity 锁屏与 Dynamic Island 紧凑 UI。
/// 仅依赖服务端推送起停；本文件不得调用 Activity.request。
@available(iOS 16.1, *)
struct PredictImminentLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PredictImminentAttributes.self) { context in
      // 锁屏 / 横幅：logo + 即将发生 + 右箭头
      HStack(spacing: 10) {
        Image("BrandLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 28, height: 28)
          .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        VStack(alignment: .leading, spacing: 2) {
          Text(context.state.title.isEmpty ? "事件即将发生" : context.state.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
          Text("即将发生")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 4)
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity/imminent"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image("BrandLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.state.title.isEmpty ? "即将发生" : context.state.title)
            .font(.caption.weight(.semibold))
            .lineLimit(2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: "chevron.right")
        }
      } compactLeading: {
        Image("BrandLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 18, height: 18)
      } compactTrailing: {
        Image(systemName: "chevron.right")
          .font(.caption2)
      } minimal: {
        Image("BrandLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
      }
      .widgetURL(URL(string: "pangbao://live-activity/imminent"))
    }
  }
}

@available(iOS 16.1, *)
struct PredictTimingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PredictTimingAttributes.self) { context in
      // 锁屏：logo + 计时中 + 已计时 + 右箭头
      HStack(spacing: 10) {
        Image("BrandLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 28, height: 28)
          .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        VStack(alignment: .leading, spacing: 2) {
          Text(context.state.eventName.isEmpty ? "事件计时中" : "\(context.state.eventName)计时中")
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
          TimingElapsedText(startUnix: context.state.startTime)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 4)
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity/timing"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image("BrandLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.eventName.isEmpty ? "计时中" : context.state.eventName)
              .font(.caption.weight(.semibold))
              .lineLimit(1)
            TimingElapsedText(startUnix: context.state.startTime)
              .font(.caption2.monospacedDigit())
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: "chevron.right")
        }
      } compactLeading: {
        Image("BrandLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 18, height: 18)
      } compactTrailing: {
        TimingElapsedText(startUnix: context.state.startTime)
          .font(.caption2.monospacedDigit())
      } minimal: {
        Image(systemName: "timer")
      }
      .widgetURL(URL(string: "pangbao://live-activity/timing"))
    }
  }
}

/// 根据 start unix 秒展示已计时长（TimelineView 每秒刷新）。
@available(iOS 16.1, *)
private struct TimingElapsedText: View {
  let startUnix: Int64

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      Text(Self.formatElapsed(startUnix: startUnix, now: context.date))
    }
  }

  /// 不足 1 小时 MM:SS，否则 HH:MM:SS。
  static func formatElapsed(startUnix: Int64, now: Date) -> String {
    let start = Date(timeIntervalSince1970: TimeInterval(max(0, startUnix)))
    let sec = max(0, Int(now.timeIntervalSince(start)))
    let h = sec / 3600
    let m = (sec % 3600) / 60
    let s = sec % 60
    if h > 0 {
      return String(format: "%02d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
  }
}
