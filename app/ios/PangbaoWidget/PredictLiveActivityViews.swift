import ActivityKit
import SwiftUI
import WidgetKit

/// Imminent / Timing Live Activity 锁屏与 Dynamic Island。
/// 仅依赖服务端推送起停；本文件不得调用 Activity.request。
@available(iOS 16.1, *)
struct PredictImminentLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PredictImminentAttributes.self) { context in
      let visual = WidgetVisualHelpers.visual(forEventId: context.attributes.eventId)
      let accent = WidgetVisualHelpers.laAccentColor(visual.color)
      let nextUnix = context.state.nextAt > 0
        ? context.state.nextAt
        : context.attributes.nextAt
      HStack(spacing: 10) {
        WidgetVisualHelpers.eventLogo(
          path: visual.logoFile,
          color: visual.color,
          size: 28
        )
        Text(context.state.title.isEmpty ? "事件即将发生" : context.state.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(2)
        Spacer(minLength: 4)
        ImminentCountdownText(nextUnix: nextUnix)
          .font(.title3.monospacedDigit().weight(.semibold))
          .foregroundStyle(accent)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity/imminent"))
    } dynamicIsland: { context in
      let visual = WidgetVisualHelpers.visual(forEventId: context.attributes.eventId)
      let accent = WidgetVisualHelpers.laAccentColor(visual.color)
      let nextUnix = context.state.nextAt > 0
        ? context.state.nextAt
        : context.attributes.nextAt
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          WidgetVisualHelpers.eventLogo(
            path: visual.logoFile,
            color: visual.color,
            size: 24
          )
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.state.title.isEmpty ? "即将发生" : context.state.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .lineLimit(2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          ImminentCountdownText(nextUnix: nextUnix)
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(accent)
        }
      } compactLeading: {
        WidgetVisualHelpers.eventLogo(
          path: visual.logoFile,
          color: visual.color,
          size: 18
        )
      } compactTrailing: {
        ImminentCountdownText(nextUnix: nextUnix)
          .font(.caption2.monospacedDigit())
          .foregroundStyle(accent)
      } minimal: {
        WidgetVisualHelpers.eventLogo(
          path: visual.logoFile,
          color: visual.color,
          size: 16
        )
      }
      .widgetURL(URL(string: "pangbao://live-activity/imminent"))
    }
  }
}

@available(iOS 16.1, *)
struct PredictTimingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PredictTimingAttributes.self) { context in
      let visual = WidgetVisualHelpers.visual(forEventId: context.attributes.eventId)
      let accent = WidgetVisualHelpers.laAccentColor(visual.color)
      HStack(alignment: .center, spacing: 10) {
        WidgetVisualHelpers.eventLogo(
          path: visual.logoFile,
          color: visual.color,
          size: 28
        )
        Text(
          context.state.eventName.isEmpty
            ? "事件计时中"
            : "\(context.state.eventName)计时中"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(accent)
        .lineLimit(2)
        Spacer(minLength: 4)
        TimingElapsedText(startUnix: context.state.startTime)
          .font(.title3.monospacedDigit().weight(.semibold))
          .foregroundStyle(accent)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity/timing"))
    } dynamicIsland: { context in
      let visual = WidgetVisualHelpers.visual(forEventId: context.attributes.eventId)
      let accent = WidgetVisualHelpers.laAccentColor(visual.color)
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          WidgetVisualHelpers.eventLogo(
            path: visual.logoFile,
            color: visual.color,
            size: 24
          )
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.state.eventName.isEmpty ? "计时中" : context.state.eventName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .lineLimit(1)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TimingElapsedText(startUnix: context.state.startTime)
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(accent)
        }
      } compactLeading: {
        WidgetVisualHelpers.eventLogo(
          path: visual.logoFile,
          color: visual.color,
          size: 18
        )
      } compactTrailing: {
        TimingElapsedText(startUnix: context.state.startTime)
          .font(.caption2.monospacedDigit())
          .foregroundStyle(accent)
      } minimal: {
        Image(systemName: "timer")
      }
      .widgetURL(URL(string: "pangbao://live-activity/timing"))
    }
  }
}

/// 距 nextAt 倒计时；到点显示「已过时」。
@available(iOS 16.1, *)
private struct ImminentCountdownText: View {
  let nextUnix: Int64

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      let end = Date(timeIntervalSince1970: TimeInterval(max(0, nextUnix)))
      if context.date >= end || nextUnix <= 0 {
        Text("已过时")
      } else {
        Text(
          timerInterval: context.date...end,
          countsDown: true,
          showsHours: true
        )
      }
    }
  }
}

/// 自 start unix 秒起的已计时（系统 timerInterval）。
@available(iOS 16.1, *)
private struct TimingElapsedText: View {
  let startUnix: Int64

  var body: some View {
    let start = Date(timeIntervalSince1970: TimeInterval(max(0, startUnix)))
    // countsDown: false → 从 start 向上累加
    Text(
      timerInterval: start...Date.distantFuture,
      countsDown: false,
      showsHours: true
    )
  }
}
