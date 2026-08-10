/// 桌面小组件常量（Flutter / native 对齐）。
abstract final class HomeWidgetConstants {
  static const appGroupId = 'group.com.fzy.pangbao.widget';
  static const payloadKey = 'widgetPayload';

  static const androidSmallName = 'PangbaoWidgetSmallProvider';
  static const androidMediumName = 'PangbaoWidgetMediumProvider';
  static const androidLargeName = 'PangbaoWidgetLargeProvider';

  static const iOSWidgetName = 'PangbaoWidget';

  static const emptyMessage = '打开胖宝记录';
  static const noPredictionMessage = '继续记录以生成预测';
  static const loadingMessage = '正在准备数据…';

  /// 预测/小组件历史深度（自然日，含今天共 7 日）。
  static const prefetchDaySpan = 7;
  static const prefetchTimeout = Duration(seconds: 30);
  static const maxConsecutivePageFailures = 3;
}
