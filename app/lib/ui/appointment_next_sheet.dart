import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/appointment_event.dart';
import '../data/appointment_next_repository.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../providers/appointment_next_provider.dart';
import '../theme/app_color.dart';
import 'event_logo.dart';
import 'glass_single_wheel_picker_sheet.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/keyboard_lift.dart';

/// 专用 sheet 确认结果：下次时间 + 备注（不 Trim）。
class AppointmentNextSheetResult {
  const AppointmentNextSheetResult({
    required this.nextAt,
    required this.remark,
  });

  final DateTime nextAt;
  final String remark;
}

/// 专用「下一次预约」sheet：确认返回所选本地时间+备注；关闭返回 null。无清空。
Future<AppointmentNextSheetResult?> showAppointmentNextSheet(
  BuildContext context, {
  required EventDefinition event,
  DateTime? initialNextAt,
  String initialRemark = '',
}) {
  final accent = resolveEventColor(context, event);
  // 横屏抬高占比；整窗可滚，矮约束/键盘下可滚到备注与确认
  final landscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;
  return showGlassAdaptiveBottomSheet<AppointmentNextSheetResult>(
    context: context,
    eventAccent: accent,
    scrollable: true,
    // 与新增事件 sheet 同族：键盘升起时垫高，避免备注被盖
    respectKeyboardInset: true,
    maxHeightFraction: landscape ? 0.95 : 0.72,
    bodyBuilder: (ctx) => _AppointmentNextSheetBody(
      event: event,
      initialNextAt: initialNextAt,
      initialRemark: initialRemark,
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
  String? initialRemark,
}) async {
  // 优先用入参备注；否则从缓存/GET 回填
  var remark = initialRemark;
  if (remark == null) {
    final cached = ref.read(appointmentNextCacheProvider)[rootEventId.trim()];
    if (cached != null) {
      remark = cached.remark;
    } else {
      final v = await ensureAppointmentNext(ref, rootEventId);
      remark = v.remark;
    }
  }
  if (!context.mounted) return false;
  final picked = await showAppointmentNextSheet(
    context,
    event: displayEvent,
    initialNextAt: initialNextAt,
    initialRemark: remark,
  );
  if (picked == null || !context.mounted) return false;
  final ok = await putAppointmentNext(
    ref: ref,
    rootEventId: rootEventId,
    nextAtSec: appointmentNextAtToSec(picked.nextAt),
    remark: picked.remark,
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
  final value = await ensureAppointmentNext(ref, rootId);
  if (!context.mounted) return;
  if (!appointmentNextAtEmptyOrOverdue(value.nextAtSec, DateTime.now())) {
    return;
  }
  final initial = appointmentNextAtFromSec(value.nextAtSec);
  await showAppointmentNextSheetAndSave(
    context,
    ref: ref,
    rootEventId: rootId,
    displayEvent: rootDef,
    initialNextAt: initial,
    initialRemark: value.remark,
  );
}

/// 正常新增成功后：先清空 nextAt，成功再弹专用 sheet；清空失败不弹。
/// 清空前快照约定备注（clear 会清本地 remark），弹 sheet 时预填。
Future<void> clearThenPromptAppointmentNextAfterAdd({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  required List<EventDefinition> catalog,
}) async {
  if (!eventIsAppointment(event, catalog)) return;
  final rootId = appointmentRootEventId(event.id, catalog);
  final rootDef = lookupEventById(catalog, rootId) ?? event;
  // 必须在 clear 之前读备注：clearAppointmentNextAt 会把缓存 remark 置空
  final prior = await ensureAppointmentNext(ref, rootId);
  final remarkSnapshot = prior.remark;
  if (!context.mounted) return;
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
    initialRemark: remarkSnapshot,
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
    this.initialRemark = '',
  });

  final EventDefinition event;
  final DateTime? initialNextAt;
  final String initialRemark;

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

  /// 备注由 State 持有并 dispose（禁止弹层返回后 dispose）。
  late final TextEditingController _remarkCtrl;
  late final FocusNode _remarkFocus;
  final _remarkAnchorKey = GlobalKey();

  /// 备注获焦时收起滚轮（与键盘 inset 配合）。
  var _remarkFocused = false;

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
    // 回填上次预约备注（不 Trim）
    _remarkCtrl = TextEditingController(text: widget.initialRemark);
    _remarkFocus = FocusNode();
    _remarkFocus.addListener(_onRemarkFocusChange);
  }

  void _onRemarkFocusChange() {
    final focused = _remarkFocus.hasFocus;
    if (focused == _remarkFocused) return;
    setState(() => _remarkFocused = focused);
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

  void _confirm() {
    Navigator.pop(
      context,
      AppointmentNextSheetResult(
        nextAt: _selected,
        // 原样提交，不 Trim
        remark: clampAppointmentRemark(_remarkCtrl.text),
      ),
    );
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _remarkFocus.removeListener(_onRemarkFocusChange);
    _remarkFocus.dispose();
    _remarkCtrl.dispose();
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
    // 备注获焦或键盘可见：收起四列滚轮腾出高度
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final collapseWheels = _remarkFocused || keyboardVisible;

    // 整窗可滚：内容用固有高度；滚轮固定高，不依赖 Expanded
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final tight = landscape;
    final gapAfterTitle = tight ? 4.0 : 10.0;
    final gapAfterYear = tight ? 4.0 : 8.0;
    final gapBeforeRemark = tight ? 4.0 : 8.0;
    final gapBeforeBtn = tight ? 6.0 : 12.0;
    final btnH = tight ? 36.0 : 44.0;
    final wheelsH = tight ? 160.0 : 200.0;

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

          // 预约备注输入（与 nextAt 一并 PUT）；keyboardLift 锚点
          final remarkField = Padding(
            padding: EdgeInsets.only(top: gapBeforeRemark),
            child: keyboardLiftTarget(
              focusNode: _remarkFocus,
              anchorKey: _remarkAnchorKey,
              child: TextField(
                controller: _remarkCtrl,
                focusNode: _remarkFocus,
                maxLines: 1,
                style: TextStyle(fontSize: tight ? 13 : 14, color: glassText),
                cursorColor: scheme.primary,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kAppointmentRemarkMaxLen),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '备注（可选）',
                  hintStyle: TextStyle(
                    color: glassText.withValues(alpha: 0.45),
                    fontSize: tight ? 13 : 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: tight ? 8 : 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.primary),
                  ),
                ),
              ),
            ),
          );

          final footer = <Widget>[
            remarkField,
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

    // 收起滚轮：仅标题+年份+备注+确认；否则固定高滚轮，整窗由外壳滚动
    final bodyChildren = <Widget>[
      ...header,
      if (!collapseWheels) SizedBox(height: wheelsH, child: wheels),
      ...footer,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: bodyChildren,
      ),
    );
  }
}
