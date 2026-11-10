import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

/// 统一列表态 Live Activity：锁屏按 items 纵向堆叠；Island 优先首条 timing，否则 items.first。
/// 仅依赖服务端推送起停；本文件不得调用 Activity.request。
@available(iOS 16.1, *)
struct BabyLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BabyLiveActivityAttributes.self) { context in
      let items = context.state.items
      // 锁屏：仅按 items 纵向堆叠（无 App 名顶栏，减高度占位；不重排）
      VStack(alignment: .leading, spacing: 10) {
        ForEach(items) { item in
          if item.isTiming {
            LiveActivityTimingRow(item: item)
          } else if item.isImminent {
            LiveActivityImminentRow(item: item)
          }
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .activityBackgroundTint(Color.black.opacity(0.55))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "pangbao://live-activity"))
    } dynamicIsland: { context in
      let items = context.state.items
      // 优先进行中（数组中第一条 timing）；无则按序 items.first；不重排
      let selected = items.first(where: { $0.isTiming }) ?? items.first
      if let selected, selected.isTiming {
        return timingIsland(item: selected)
      }
      if let selected, selected.isImminent {
        return imminentIsland(item: selected)
      }
      return DynamicIsland {
        DynamicIslandExpandedRegion(.center) {
          EmptyView()
        }
      } compactLeading: {
        EmptyView()
      } compactTrailing: {
        EmptyView()
      } minimal: {
        EmptyView()
      }
      .widgetURL(URL(string: "pangbao://live-activity"))
    }
  }
}

// MARK: - Island（选中项）

@available(iOS 16.1, *)
private func imminentIsland(item: BabyLiveActivityItem) -> DynamicIsland {
  let visual = WidgetVisualHelpers.visual(forEventId: item.eventId)
  let accent = WidgetVisualHelpers.laAccentColor(visual.color)
  // Island 只用本地目录名；禁止回退推送 title
  let localName = compactIslandLocalName(visual.name)
  return DynamicIsland {
    DynamicIslandExpandedRegion(.leading) {
      WidgetVisualHelpers.eventLogo(path: visual.logoFile, color: visual.color, size: 24)
    }
    DynamicIslandExpandedRegion(.center) {
      // 本地名为空时用短状态词，仍不吃推送长 title
      Text(localName.isEmpty ? "即将发生" : localName)
        .font(.caption.weight(.semibold))
        .foregroundStyle(accent)
    }
    DynamicIslandExpandedRegion(.trailing) {
      // Imminent 不展示时间维
      EmptyView()
    }
  } compactLeading: {
    CompactIslandLeading(
      logoFile: visual.logoFile,
      color: visual.color,
      name: localName,
      accent: accent
    )
  } compactTrailing: {
    EmptyView()
  } minimal: {
    WidgetVisualHelpers.eventLogo(path: visual.logoFile, color: visual.color, size: 16)
  }
  .widgetURL(URL(string: "pangbao://live-activity"))
}

@available(iOS 16.1, *)
private func timingIsland(item: BabyLiveActivityItem) -> DynamicIsland {
  let visual = WidgetVisualHelpers.visual(forEventId: item.eventId)
  let accent = WidgetVisualHelpers.laAccentColor(visual.color)
  let startUnix = max(0, item.startTime)
  // Island 只用本地目录名；禁止回退推送 eventName
  let localName = compactIslandLocalName(visual.name)
  return DynamicIsland {
    DynamicIslandExpandedRegion(.leading) {
      WidgetVisualHelpers.eventLogo(path: visual.logoFile, color: visual.color, size: 24)
    }
    DynamicIslandExpandedRegion(.center) {
      Text(localName.isEmpty ? "计时中" : localName)
        .font(.caption.weight(.semibold))
        .foregroundStyle(accent)
    }
    DynamicIslandExpandedRegion(.trailing) {
      LockTimingElapsedText(startUnix: startUnix)
        .font(.caption.monospacedDigit().weight(.semibold))
        .foregroundStyle(accent)
    }
  } compactLeading: {
    CompactIslandLeading(
      logoFile: visual.logoFile,
      color: visual.color,
      name: localName,
      accent: accent
    )
  } compactTrailing: {
    CompactIslandTimeSlot {
      LockTimingElapsedText(startUnix: startUnix)
    }
    .font(.caption2.monospacedDigit())
    .foregroundStyle(accent)
  } minimal: {
    Image(systemName: "timer")
  }
  .widgetURL(URL(string: "pangbao://live-activity"))
}

// MARK: - 列表行（复用既有各态样式）

/// Imminent 行：logo + title + 可选 expect 右槽（非 nextAt 倒计时）。
@available(iOS 16.1, *)
private struct LiveActivityImminentRow: View {
  let item: BabyLiveActivityItem

  var body: some View {
    let visual = WidgetVisualHelpers.visual(forEventId: item.eventId)
    let accent = WidgetVisualHelpers.laAccentColor(visual.color)
    let expectLabel = imminentExpectTrailingLabel(
      kind: item.expectKind,
      durationSec: item.expectDurationSec,
      amount: item.expectAmount,
      unit: item.expectUnit
    )
    HStack(alignment: .center, spacing: 12) {
      WidgetVisualHelpers.eventLogo(path: visual.logoFile, color: visual.color, size: 37)
      Text(lockTitle(state: item.title, fallback: "", empty: "事件即将发生"))
        .font(.title3.weight(.semibold))
        .foregroundStyle(accent)
        .lineLimit(2)
      Spacer(minLength: 4)
      if let expectLabel, !expectLabel.isEmpty {
        Text(expectLabel)
          .font(lockTrailingFontMinus5)
          .foregroundStyle(accent)
          .lineLimit(2)
          .minimumScaleFactor(0.75)
          .multilineTextAlignment(.trailing)
      }
    }
  }
}

/// Timing 行：logo + 事件名(+副行) + 右侧已计时。
@available(iOS 16.1, *)
private struct LiveActivityTimingRow: View {
  let item: BabyLiveActivityItem

  var body: some View {
    let visual = WidgetVisualHelpers.visual(forEventId: item.eventId)
    let accent = WidgetVisualHelpers.laAccentColor(visual.color)
    let expectSubtitle = timingExpectEndSubtitle(expectEndAt: item.expectEndAt)
    HStack(alignment: .center, spacing: 12) {
      WidgetVisualHelpers.eventLogo(path: visual.logoFile, color: visual.color, size: 37)
      VStack(alignment: .leading, spacing: 2) {
        Text(timingLockTitle(state: item.eventName, fallback: ""))
          .font(.title3.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(2)
        if let expectSubtitle, !expectSubtitle.isEmpty {
          Text(expectSubtitle)
            .font(.caption.weight(.medium))
            .foregroundStyle(accent.opacity(0.9))
            .lineLimit(1)
        }
      }
      Spacer(minLength: 4)
      LockTimingElapsedText(startUnix: item.startTime)
        .font(lockTrailingTitleFont)
        .foregroundStyle(accent)
        .multilineTextAlignment(.trailing)
    }
  }
}

// MARK: - 字号 / 时间位

private var lockTrailingTitlePointSize: CGFloat {
  UIFont.preferredFont(forTextStyle: .title1).pointSize
}

private var lockTrailingTitleFont: Font {
  .system(size: lockTrailingTitlePointSize, weight: .semibold)
}

private var lockTrailingFontMinus5: Font {
  .system(size: lockTrailingTitlePointSize - 5, weight: .semibold)
}

/// Timing：系统 timerInterval 已计时（可带秒）；上界约 99 小时。
@available(iOS 16.1, *)
private struct LockTimingElapsedText: View {
  let startUnix: Int64

  var body: some View {
    let start = Date(timeIntervalSince1970: TimeInterval(max(0, startUnix)))
    let end = start.addingTimeInterval(99 * 3600)
    Text(timerInterval: start...end, countsDown: false, showsHours: true)
      .monospacedDigit()
  }
}

// MARK: - 文案 helper

/// Timing 副行：正 `expectEndAt` →「预计 HH:mm 结束」。
private func timingExpectEndSubtitle(expectEndAt: Int64) -> String? {
  guard expectEndAt > 0 else { return nil }
  let date = Date(timeIntervalSince1970: TimeInterval(expectEndAt))
  let cal = Calendar.current
  let h = cal.component(.hour, from: date)
  let m = cal.component(.minute, from: date)
  return String(format: "预计 %02d:%02d 结束", h, m)
}

/// Imminent 右槽短版；无可用 expect 返回 nil。
private func imminentExpectTrailingLabel(
  kind: String,
  durationSec: Int64,
  amount: Double,
  unit: String
) -> String? {
  let k = kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  if k == "duration" {
    guard durationSec >= 60 else { return nil }
    let h = durationSec / 3600
    let m = (durationSec % 3600) / 60
    if h >= 1 {
      if m > 0 { return "预计\(h)时\(m)分钟" }
      return "预计\(h)时"
    }
    return "预计\(m)分钟"
  }
  if k == "amount" {
    guard amount > 0 else { return nil }
    let qty = formatExpectAmountShort(amount)
    let u = unit.trimmingCharacters(in: .whitespacesAndNewlines)
    return "预计\(qty)\(u)"
  }
  return nil
}

private func formatExpectAmountShort(_ value: Double) -> String {
  if value == value.rounded() {
    return String(Int(value.rounded()))
  }
  var s = String(format: "%.1f", value)
  if s.hasSuffix(".0") {
    s = String(s.dropLast(2))
  }
  return s
}

private func lockTitle(state: String, fallback: String, empty: String) -> String {
  if !state.isEmpty { return state }
  if !fallback.isEmpty { return fallback }
  return empty
}

private func timingLockTitle(state: String, fallback: String) -> String {
  let name = state.isEmpty ? fallback : state
  return name.isEmpty ? "事件" : name
}

/// Island compact/expanded 用的本地事件名；空串表示仅 logo。
private func compactIslandLocalName(_ raw: String?) -> String {
  raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

@available(iOS 16.1, *)
private struct CompactIslandLeading: View {
  let logoFile: String?
  let color: String?
  let name: String
  let accent: Color

  var body: some View {
    // 固有宽 hug：避免吃满系统提案宽导致切口旁大片空白
    HStack(spacing: 3) {
      WidgetVisualHelpers.eventLogo(path: logoFile, color: color, size: 18)
      if !name.isEmpty {
        Text(name)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(accent)
          .lineLimit(1)
      }
    }
    .fixedSize(horizontal: true, vertical: false)
  }
}

@available(iOS 16.1, *)
private struct CompactIslandTimeSlot<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    // 短固有宽占位防 timer 测爆；外层 hug 避免再被系统拉宽
    Text("00:00:00")
      .hidden()
      .overlay(alignment: .trailing) {
        content
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
      .fixedSize(horizontal: true, vertical: false)
  }
}
