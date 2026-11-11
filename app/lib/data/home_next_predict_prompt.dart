import 'event_definition.dart';
import 'relative_calendar_day.dart';

/// 喂养页最近预测玻璃卡三态窗（独立 UI 常量，勿复用准确率命中窗）。
const kHomeNextPredictPromptWindow = Duration(minutes: 30);

/// 相对预测时刻的提示态。
enum HomeNextPredictPromptState {
  /// 距预测尚远：告知下次几点发生什么。
  farUpcoming,

  /// 落在 ±30 分钟窗内：询问是否要做。
  withinWindow,

  /// 逾期超过 30 分钟：询问是否忘了补记。
  overdueBackfill,
}

/// 按 [now] 与 [nextAt] 划分 A/B/C；窗宽 [kHomeNextPredictPromptWindow]。
HomeNextPredictPromptState homeNextPredictPromptState(
  DateTime nextAt,
  DateTime now,
) {
  final w = kHomeNextPredictPromptWindow;
  if (now.isBefore(nextAt.subtract(w))) {
    return HomeNextPredictPromptState.farUpcoming;
  }
  if (now.isAfter(nextAt.add(w))) {
    return HomeNextPredictPromptState.overdueBackfill;
  }
  return HomeNextPredictPromptState.withinWindow;
}

/// 中区主文案（不含时刻；时刻见 [homeNextPredictPromptTimeLabel]）。
String homeNextPredictPromptBody({
  required HomeNextPredictPromptState state,
  required String eventName,
}) {
  final name = eventName.trim().isEmpty ? '未命名事件' : eventName.trim();
  switch (state) {
    case HomeNextPredictPromptState.farUpcoming:
      return '下次预计$name';
    case HomeNextPredictPromptState.withinWindow:
      return '是不是该$name了？';
    case HomeNextPredictPromptState.overdueBackfill:
      return '是不是忘了补记$name？';
  }
}

/// 主文案下方小字：预计时刻（相对自然日 + 时分）。
String homeNextPredictPromptTimeLabel(DateTime nextAt, DateTime now) {
  final xx = formatRelativeCalendarDayAndTime(
    nextAt,
    now,
    omitDayWhenToday: true,
  );
  return '预计 $xx';
}

/// 右侧 CTA 文案；B 态 `time` →「开始」，否则「记录」。
String homeNextPredictPromptCtaLabel({
  required HomeNextPredictPromptState state,
  required EventCatalogEventType? eventType,
}) {
  switch (state) {
    case HomeNextPredictPromptState.farUpcoming:
      return '去记录';
    case HomeNextPredictPromptState.withinWindow:
      return eventType == EventCatalogEventType.time ? '开始' : '记录';
    case HomeNextPredictPromptState.overdueBackfill:
      return '补记';
  }
}
