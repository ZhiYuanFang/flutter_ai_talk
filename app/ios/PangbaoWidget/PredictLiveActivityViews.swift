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
      // 锁屏双层：上品牌、下事件 + 中文到分钟
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
        LockImminentMinuteText(nextUnix: nextUnix)
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
      // compact 短名来自 title，不用「即将发生」模板
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
          // Island 固定 hh:mm:ss；过期不展示时间维文案
          IslandImminentHmsText(nextUnix: nextUnix)
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
        // compact 宽度由占位槽报告；过期则空内容叠在槽上
        CompactIslandTimeSlot {
          IslandImminentHmsText(nextUnix: nextUnix)
        }
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
      let startUnix = timingStartUnix(
        state: context.state.startTime,
        fallback: context.attributes.startTime
      )
      // 锁屏双层：上品牌、下事件 + 中文已计时
      LockScreenTwoTier(
        accent: accent,
        logoFile: visual.logoFile,
        eventColor: visual.color,
        title: timingLockTitle(
          state: context.state.eventName,
          fallback: context.attributes.eventName
        )
      ) {
        LockTimingMinuteText(startUnix: startUnix)
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
      // 上层：圆形 App logo +「胖宝」，色随事件
      HStack(spacing: 6) {
        AppBrandMark(size: 18)
        Text("胖宝")
          .font(.caption.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      // 下层：事件 logo + 标题 + 右侧时间（约 ×2 尺度）
      HStack(alignment: .center, spacing: 12) {
        WidgetVisualHelpers.eventLogo(
          path: logoFile,
          color: eventColor,
          size: 56
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

/// 圆形 BrandLogo（锁屏上层品牌标）。
@available(iOS 16.1, *)
private struct AppBrandMark: View {
  let size: CGFloat

  var body: some View {
    Image("BrandLogo")
      .resizable()
      .scaledToFill()
      .frame(width: size, height: size)
      .clipShape(Circle())
  }
}

// MARK: - 锁屏中文到分钟

/// Timing：已过去h时m分钟 / h=0 省略时；不足 1 分钟按 1。
@available(iOS 16.1, *)
private struct LockTimingMinuteText: View {
  let startUnix: Int64

  var body: some View {
    // 锁屏约分钟档刷新；不绑秒级 timerInterval
    TimelineView(.periodic(from: .now, by: 60)) { context in
      Text(timingElapsedChinese(now: context.date, startUnix: startUnix))
    }
  }
}

/// Imminent：「预计m分钟后」；过期不渲染。
@available(iOS 16.1, *)
private struct LockImminentMinuteText: View {
  let nextUnix: Int64

  var body: some View {
    TimelineView(.periodic(from: .now, by: 60)) { context in
      if let copy = imminentRemainingChinese(now: context.date, nextUnix: nextUnix) {
        Text(copy)
      }
    }
  }
}

/// 已计时 →「已过去h时m分钟」或「已过去m分钟」。
private func timingElapsedChinese(now: Date, startUnix: Int64) -> String {
  let start = Date(timeIntervalSince1970: TimeInterval(max(0, startUnix)))
  let elapsed = max(0, now.timeIntervalSince(start))
  // 不足 1 分钟（含刚开始 0 秒）按 1 分钟
  let totalMinutes = max(1, Int(ceil(elapsed / 60.0)))
  let hours = totalMinutes / 60
  let minutes = totalMinutes % 60
  if hours >= 1 {
    return "已过去\(hours)时\(minutes)分钟"
  }
  return "已过去\(totalMinutes)分钟"
}

/// 距 nextAt →「预计m分钟后」；过期返回 nil（无时间维文案）。
private func imminentRemainingChinese(now: Date, nextUnix: Int64) -> String? {
  if nextUnix <= 0 { return nil }
  let end = Date(timeIntervalSince1970: TimeInterval(nextUnix))
  let remaining = end.timeIntervalSince(now)
  if remaining <= 0 { return nil }
  // 不足 1 分钟按 1；超过 1h 仍用总分钟（如 90）
  let totalMinutes = max(1, Int(ceil(remaining / 60.0)))
  return "预计\(totalMinutes)分钟后"
}

// MARK: - Island hh:mm:ss

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

/// Imminent 倒计时：始终零填充 hh:mm:ss；过期空。
@available(iOS 16.1, *)
private struct IslandImminentHmsText: View {
  let nextUnix: Int64

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      if nextUnix > 0 {
        let end = Date(timeIntervalSince1970: TimeInterval(nextUnix))
        let remaining = Int(end.timeIntervalSince(context.date))
        if remaining > 0 {
          Text(formatHms(remaining))
        }
      }
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
  return name.isEmpty ? "事件计时中" : "\(name)计时中"
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
