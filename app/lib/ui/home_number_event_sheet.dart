import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import 'event_record_sheet.dart';

/// number 类型事件二级页确认结果（兼容旧调用方）。
class HomeNumberEventResult {
  const HomeNumberEventResult({
    required this.startTime,
    required this.eventNumber,
    required this.remark,
  });

  final DateTime startTime;
  final int eventNumber;
  final String remark;
}

/// number 新增：薄封装统一 [showEventRecordCreateSheet]。
Future<HomeNumberEventResult?> showHomeNumberEventSheet(
  BuildContext context,
  EventDefinition event, {
  int? initialUsage,
}) async {
  final r = await showEventRecordCreateSheet(
    context,
    intent: EventRecordIntent.add,
    event: event,
    initialUsage: initialUsage,
  );
  if (r == null) return null;
  return HomeNumberEventResult(
    startTime: r.startTime,
    eventNumber: r.eventNumber,
    remark: r.remark,
  );
}
