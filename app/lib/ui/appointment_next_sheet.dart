import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/appointment_event.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../providers/appointment_next_provider.dart';
import '../theme/app_color.dart';
import 'event_logo.dart';
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
  return showGlassAdaptiveBottomSheet<DateTime>(
    context: context,
    eventAccent: accent,
    scrollable: false,
    maxHeightFraction: 0.55,
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

/// 新增/补充成功后：仅空或过期时弹专用 sheet。
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
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initialNextAt;
    // 无约定时默认约一周后；过期则从现在起
    if (init != null && init.isAfter(now)) {
      _selected = init;
    } else {
      _selected = now.add(const Duration(days: 7));
    }
  }

  void _confirm() => Navigator.pop(context, _selected);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glassText = historyEditGlassTextColor(context);
    final name = widget.event.name.trim().isEmpty
        ? '事件'
        : widget.event.name.trim();
    final min = DateTime(2000);
    final max = DateTime.now().add(const Duration(days: 365 * 5));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 上方：logo + 文案
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EventLogo(definition: widget.event, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '下一次$name预约时间',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: glassText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 下方：年月日时分滚轮
          CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: scheme.primary,
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: glassText,
                        ),
              ),
            ),
            child: SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                use24hFormat: true,
                minuteInterval: 1,
                initialDateTime: _selected.isBefore(min)
                    ? min
                    : (_selected.isAfter(max) ? max : _selected),
                minimumDate: min,
                maximumDate: max,
                onDateTimeChanged: (v) => setState(() => _selected = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: AppColor.onPrimary(context),
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _confirm,
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
