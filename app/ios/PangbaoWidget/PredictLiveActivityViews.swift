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
      // 锁屏双层：上品牌名、下事件；无时间维
      LockScreenTwoTier(
        accent: accent,
        logoFile: visual.logoFile,
        eventColor: visual.color,
        title: lockTitle(
          state: context.state.title,
          fallback: context.attributes.title,
          empty: "事件即将发生"
        )
      ) {
        EmptyView()
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity/imminent"))
    } dynamicIsland: { context in
      let visual = WidgetVisualHelpers.visual(forEventId: context.attributes.eventId)
      let accent = WidgetVisualHelpers.laAccentColor(visual.color)
      // compact 短名来自 title；标题可留「即将发生」，无时间维
      let compactName = compactIslandName(
        state: context.state.title,
        fallback: context.attributes.title
      )
      // 有 let 后须显式 return DynamicIsland
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          WidgetVisualHelpers.eventLogo(
            path: visual.logoFile,
            color: visual.color,
            size: 24
          )
        }
        DynamicIslandExpandedRegion(.center) {
          Text(lockTitle(state: context.state.title, fallback: context.attributes.title, empty: "即将发生"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .lineLimit(2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          // 预计事件不展示时间维
          EmptyView()
        }
      } compactLeading: {
        CompactIslandLeading(
          logoFile: visual.logoFile,
          color: visual.color,
          name: compactName,
          accent: accent
        )
      } compactTrailing: {
        // 收掉右槽，不预留 timer 宽
        EmptyView()
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
      let startUnix = timingStartUnix(
        state: context.state.startTime,
        fallback: context.attributes.startTime
      )
      // 锁屏双层：上品牌名、下事件 + 系统 timer 已计时
      LockScreenTwoTier(
        accent: accent,
        logoFile: visual.logoFile,
        eventColor: visual.color,
        title: timingLockTitle(
          state: context.state.eventName,
          fallback: context.attributes.eventName
        )
      ) {
        LockTimingElapsedText(startUnix: startUnix)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity/timing"))
    } dynamicIsland: { context in
      let visual = WidgetVisualHelpers.visual(forEventId: context.attributes.eventId)
      let accent = WidgetVisualHelpers.laAccentColor(visual.color)
      let startUnix = timingStartUnix(
        state: context.state.startTime,
        fallback: context.attributes.startTime
      )
      // compact 短名来自 eventName，不用「计时中」模板
      let compactName = compactIslandName(
        state: context.state.eventName,
        fallback: context.attributes.eventName
      )
      // 有 let 后须显式 return DynamicIsland
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          WidgetVisualHelpers.eventLogo(
            path: visual.logoFile,
            color: visual.color,
            size: 24
          )
        }
        DynamicIslandExpandedRegion(.center) {
          Text(timingIslandTitle(state: context.state.eventName, fallback: context.attributes.eventName))
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .lineLimit(1)
        }
        DynamicIslandExpandedRegion(.trailing) {
          // Island 已计时固定 hh:mm:ss
          IslandTimingHmsText(startUnix: startUnix)
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(accent)
        }
      } compactLeading: {
        CompactIslandLeading(
          logoFile: visual.logoFile,
          color: visual.color,
          name: compactName,
          accent: accent
        )
      } compactTrailing: {
        // compact 宽度由占位槽报告，已计时不得撑开岛
        CompactIslandTimeSlot {
          IslandTimingHmsText(startUnix: startUnix)
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(accent)
      } minimal: {
        Image(systemName: "timer")
      }
      .widgetURL(URL(string: "pangbao://live-activity/timing"))
    }
  }
}

// MARK: - 锁屏双层

/// 上层窄品牌行 + 下层宽事件行；时间位由 trailing 注入（可空）。
@available(iOS 16.1, *)
private struct LockScreenTwoTier<Trailing: View>: View {
  let accent: Color
  let logoFile: String?
  let eventColor: String?
  let title: String
  let trailing: Trailing

  init(
    accent: Color,
    logoFile: String?,
    eventColor: String?,
    title: String,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.accent = accent
    self.logoFile = logoFile
    self.eventColor = eventColor
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 上层：仅「胖宝」文字，无 App 圆标
      HStack(spacing: 6) {
        Text("胖宝")
          .font(.caption.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      // 下层：事件 logo（约原 56 的 2/3）+ 标题 + 右侧时间
      HStack(alignment: .center, spacing: 12) {
        WidgetVisualHelpers.eventLogo(
          path: logoFile,
          color: eventColor,
          size: 37
        )
        Text(title)
          .font(.title3.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(2)
        Spacer(minLength: 4)
        trailing
          .font(.title.weight(.semibold))
          .foregroundStyle(accent)
          .multilineTextAlignment(.trailing)
      }
    }
  }
}

// MARK: - 锁屏时间位

/// Timing：系统 timerInterval 已计时（可带秒）；上界约 99 小时。
@available(iOS 16.1, *)
private struct LockTimingElapsedText: View {
  let startUnix: Int64

  var body: some View {
    let start = Date(timeIntervalSince1970: TimeInterval(max(0, startUnix)))
    // 有限上界，避免 distantFuture 测量副作用
    let end = start.addingTimeInterval(99 * 3600)
    Text(timerInterval: start...end, countsDown: false, showsHours: true)
      .monospacedDigit()
  }
}

// MARK: - Island hh:mm:ss（仅 Timing）

/// Timing 已计时：始终零填充 hh:mm:ss。
@available(iOS 16.1, *)
private struct IslandTimingHmsText: View {
  let startUnix: Int64

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      let start = Date(timeIntervalSince1970: TimeInterval(max(0, startUnix)))
      let elapsed = max(0, Int(context.date.timeIntervalSince(start)))
      Text(formatHms(elapsed))
    }
  }
}

/// 秒 → `hh:mm:ss`（两位时分秒，不足 1h 仍含时）。
private func formatHms(_ totalSeconds: Int) -> String {
  let s = max(0, totalSeconds)
  let h = s / 3600
  let m = (s % 3600) / 60
  let sec = s % 60
  return String(format: "%02d:%02d:%02d", h, m, sec)
}

// MARK: - 标题与 compact 名

/// ContentState 文案为空时回退固定 Attributes（Push-to-Start 常不套用 content-state）。
private func lockTitle(state: String, fallback: String, empty: String) -> String {
  if !state.isEmpty { return state }
  if !fallback.isEmpty { return fallback }
  return empty
}

private func timingLockTitle(state: String, fallback: String) -> String {
  let name = state.isEmpty ? fallback : state
  // 锁屏标题仅事件名，不拼「计时中」
  return name.isEmpty ? "事件" : name
}

private func timingIslandTitle(state: String, fallback: String) -> String {
  let name = state.isEmpty ? fallback : state
  return name.isEmpty ? "计时中" : name
}

private func timingStartUnix(state: Int64, fallback: Int64) -> Int64 {
  state > 0 ? state : fallback
}

/// compact 短名：ContentState 优先，trim 后最多 3 个 Character；空则空串，无省略号。
private func compactIslandName(state: String, fallback: String) -> String {
  let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)
  let raw = trimmedState.isEmpty
    ? fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    : trimmedState
  if raw.isEmpty { return "" }
  // String.prefix 按 Character 计，不是 UTF-16
  return String(raw.prefix(3))
}

/// compact 左侧：logo + 最多三字；空名则只 logo。
@available(iOS 16.1, *)
private struct CompactIslandLeading: View {
  let logoFile: String?
  let color: String?
  let name: String
  let accent: Color

  var body: some View {
    HStack(spacing: 3) {
      WidgetVisualHelpers.eventLogo(path: logoFile, color: color, size: 18)
      if !name.isEmpty {
        Text(name)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(1)
      }
    }
  }
}

/// compact 岛固有宽度由隐藏占位报告；真内容叠在槽内，不得决定岛宽。
@available(iOS 16.1, *)
private struct CompactIslandTimeSlot<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    // 等宽 "00:00:00" 作为胶囊宽度；hidden 仍占布局
    Text("00:00:00")
      .hidden()
      .overlay(alignment: .trailing) {
        // hh:mm:ss 或过期空内容画在占位上，超宽则缩小
        content
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
  }
}
