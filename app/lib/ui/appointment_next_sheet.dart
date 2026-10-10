import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/appointment_event.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../providers/appointment_next_provider.dart';
import '../theme/app_color.dart';
import 'event_logo.dart';
import 'glass_single_wheel_picker_sheet.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

/// 专用「下一次预约」sheet：确认返回所选本地时间；关闭返回 null。无清空。
Future<DateTime?> showAppointmentNextSheet(
  BuildContext context, {
  required EventDefinition event,
  DateTime? initialNextAt,
}) {
  final accent = resolveEventColor(context, event);
  // 横屏可用高度紧，抬高占比避免四列滚轮被裁切
  final landscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;
  return showGlassAdaptiveBottomSheet<DateTime>(
    context: context,
    eventAccent: accent,
    scrollable: false,
    maxHeightFraction: landscape ? 0.92 : 0.62,
    bodyBuilder: (ctx) => _AppointmentNextSheetBody(
      event: event,
      initialNextAt: initialNextAt,
    ),
  );
}

/// 拉取/确认写入后返回是否已写入正 nextAt。
Future<bool> showAppointmentNextSheetAndSave(
  BuildContext context, {
  required WidgetRef ref,
  required String rootEventId,
  required EventDefinition displayEvent,
  DateTime? initialNextAt,
}) async {
  final picked = await showAppointmentNextSheet(
    context,
    event: displayEvent,
    initialNextAt: initialNextAt,
  );
  if (picked == null || !context.mounted) return false;
  final ok = await putAppointmentNextAt(
    ref: ref,
    rootEventId: rootEventId,
    nextAtSec: appointmentNextAtToSec(picked),
  );
  if (!ok && context.mounted) {
    showAppToast('保存预约时间失败', tone: AppToastTone.error);
  }
  return ok;
}

/// 补充成功后：仅空或过期时弹专用 sheet（不清空）。
Future<void> maybePromptAppointmentNextAfterWrite({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  required List<EventDefinition> catalog,
}) async {
  if (!eventIsAppointment(event, catalog)) return;
  final rootId = appointmentRootEventId(event.id, catalog);
  final rootDef = lookupEventById(catalog, rootId) ?? event;
  final sec = await ensureAppointmentNextAt(ref, rootId);
  if (!context.mounted) return;
  if (!appointmentNextAtEmptyOrOverdue(sec, DateTime.now())) return;
  final initial = appointmentNextAtFromSec(sec);
  await showAppointmentNextSheetAndSave(
    context,
    ref: ref,
    rootEventId: rootId,
    displayEvent: rootDef,
    initialNextAt: initial,
  );
}

/// 正常新增成功后：先清空 nextAt，成功再弹专用 sheet；清空失败不弹。
Future<void> clearThenPromptAppointmentNextAfterAdd({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  required List<EventDefinition> catalog,
}) async {
  if (!eventIsAppointment(event, catalog)) return;
  final rootId = appointmentRootEventId(event.id, catalog);
  final rootDef = lookupEventById(catalog, rootId) ?? event;
  final cleared = await clearAppointmentNextAt(ref: ref, rootEventId: rootId);
  if (!context.mounted) return;
  if (!cleared) {
    showAppToast('清空预约时间失败', tone: AppToastTone.error);
    return;
  }
  await showAppointmentNextSheetAndSave(
    context,
    ref: ref,
    rootEventId: rootId,
    displayEvent: rootDef,
    initialNextAt: null,
  );
}

/// 某年月合法天数。
int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

class _AppointmentNextSheetBody extends StatefulWidget {
  const _AppointmentNextSheetBody({
    required this.event,
    this.initialNextAt,
  });

  final EventDefinition event;
  final DateTime? initialNextAt;

  @override
  State<_AppointmentNextSheetBody> createState() =>
      _AppointmentNextSheetBodyState();
}

class _AppointmentNextSheetBodyState extends State<_AppointmentNextSheetBody> {
  static const _minYear = 2000;

  late final int _maxYear;
  late int _year;
  late int _month;
  late int _day;
  late int _hour;
  late int _minute;

  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _maxYear = now.year + 5;
    final init = widget.initialNextAt;
    // 无约定时默认约一周后；过期则从一周后起
    final DateTime selected;
    if (init != null && init.isAfter(now)) {
      selected = init;
    } else {
      selected = now.add(const Duration(days: 7));
    }
    final clamped = _clampToRange(selected);
    _year = clamped.year;
    _month = clamped.month;
    _day = clamped.day;
    _hour = clamped.hour;
    _minute = clamped.minute;

    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  DateTime _clampToRange(DateTime t) {
    final min = DateTime(_minYear, 1, 1);
    final max = DateTime(_maxYear, 12, 31, 23, 59);
    if (t.isBefore(min)) return min;
    if (t.isAfter(max)) return max;
    return t;
  }

  DateTime get _selected => DateTime(_year, _month, _day, _hour, _minute);

  void _clampDayForMonth() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day <= maxDay) return;
    _day = maxDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  /// 标题下年份行：再开一层 glass 单列年轮。
  Future<void> _pickYear() async {
    final labels = [
      for (var y = _minYear; y <= _maxYear; y++) '$y年',
    ];
    final idx = await showGlassSingleWheelPickerSheet(
      context,
      title: '选择年份',
      labels: labels,
      initialIndex: (_year - _minYear).clamp(0, labels.length - 1),
    );
    if (!mounted || idx == null) return;
    setState(() {
      _year = _minYear + idx;
      _clampDayForMonth();
    });
  }

  void _confirm() => Navigator.pop(context, _selected);

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  Widget _col({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) label,
    required ValueChanged<int> onChanged,
    required Color glassText,
    required Color primary,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 36,
        magnification: 1.05,
        useMagnifier: true,
        onSelectedItemChanged: onChanged,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: primary.withValues(alpha: 0.12),
        ),
        children: List.generate(
          itemCount,
          (i) => Center(
            child: Text(
              label(i),
              style: TextStyle(
                fontSize: 16,
                color: glassText,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glassText = historyEditGlassTextColor(context);
    final name = widget.event.name.trim().isEmpty
        ? '事件'
        : widget.event.name.trim();
    final dayCount = _daysInMonth(_year, _month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.hasBoundedHeight &&
              constraints.maxHeight.isFinite &&
              constraints.maxHeight > 0;
          // 横屏等矮约束：压缩间距与按钮，滚轮用 Expanded 吃剩余
          final tight = bounded && constraints.maxHeight < 280;
          final gapAfterTitle = tight ? 4.0 : 10.0;
          final gapAfterYear = tight ? 4.0 : 8.0;
          final gapBeforeBtn = tight ? 6.0 : 12.0;
          final btnH = tight ? 36.0 : 44.0;

          final wheels = CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: scheme.primary,
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                pickerTextStyle:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: glassText,
                        ),
              ),
            ),
            child: Row(
              children: [
                _col(
                  controller: _monthCtrl,
                  itemCount: 12,
                  label: (i) => '${i + 1}月',
                  primary: scheme.primary,
                  glassText: glassText,
                  onChanged: (i) {
                    setState(() {
                      _month = i + 1;
                      _clampDayForMonth();
                    });
                  },
                ),
                _col(
                  controller: _dayCtrl,
                  itemCount: dayCount,
                  label: (i) => '${i + 1}日',
                  primary: scheme.primary,
                  glassText: glassText,
                  onChanged: (i) {
                    setState(() => _day = i + 1);
                  },
                ),
                _col(
                  controller: _hourCtrl,
                  itemCount: 24,
                  label: (i) => '${i.toString().padLeft(2, '0')}时',
                  primary: scheme.primary,
                  glassText: glassText,
                  onChanged: (i) {
                    setState(() => _hour = i);
                  },
                ),
                _col(
                  controller: _minuteCtrl,
                  itemCount: 60,
                  label: (i) => '${i.toString().padLeft(2, '0')}分',
                  primary: scheme.primary,
                  glassText: glassText,
                  onChanged: (i) {
                    setState(() => _minute = i);
                  },
                ),
              ],
            ),
          );

          final header = <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EventLogo(
                  definition: widget.event,
                  size: tight ? 24 : 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '下一次$name预约时间',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: tight ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: glassText,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: gapAfterTitle),
            Center(
              child: InkWell(
                onTap: _pickYear,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: tight ? 2 : 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_year年',
                        style: TextStyle(
                          fontSize: tight ? 16 : 17,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more,
                        size: tight ? 20 : 22,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: gapAfterYear),
          ];

          final footer = <Widget>[
            SizedBox(height: gapBeforeBtn),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: AppColor.onPrimary(context),
                shape: const StadiumBorder(),
                minimumSize: Size.fromHeight(btnH),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _confirm,
              child: const Text('确认'),
            ),
          ];

          if (!bounded) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                SizedBox(height: 200, child: wheels),
                ...footer,
              ],
            );
          }

          // 填满可用高度，滚轮 Expanded，避免固定 200 在横屏溢出
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Expanded(child: wheels),
                ...footer,
              ],
            ),
          );
        },
      ),
    );
  }
}
