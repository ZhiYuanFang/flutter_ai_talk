import 'dart:async';

import 'package:flutter/material.dart';

import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/models.dart';
import 'event_logo.dart';
import 'home_history_edit_glass_panel.dart';

typedef ActiveTimingStopCallback = Future<bool> Function(HistoryRecord record);

/// 查询记录是否仍在计时（用于 stop 回调与列表状态对账）。
typedef ActiveTimingStillTimingCallback = bool Function(String recordId);

/// 新增成功后提醒用户：其它事件仍在计时，可选部分结束。
Future<void> showHomeActiveTimingReminderDialog({
  required BuildContext context,
  required List<HistoryRecord> candidates,
  required List<EventDefinition> eventCatalog,
  required ActiveTimingStopCallback onStop,
  ActiveTimingStillTimingCallback? isRecordActivelyTiming,
  void Function(String message)? onToast,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    useRootNavigator: true,
    builder: (dialogContext) => _ActiveTimingReminderDialog(
      routeContext: dialogContext,
      candidates: candidates,
      eventCatalog: eventCatalog,
      onStop: onStop,
      isRecordActivelyTiming: isRecordActivelyTiming,
      onToast: onToast,
    ),
  );
}

class _ActiveTimingReminderDialog extends StatefulWidget {
  const _ActiveTimingReminderDialog({
    required this.routeContext,
    required this.candidates,
    required this.eventCatalog,
    required this.onStop,
    this.isRecordActivelyTiming,
    this.onToast,
  });

  final BuildContext routeContext;
  final List<HistoryRecord> candidates;
  final List<EventDefinition> eventCatalog;
  final ActiveTimingStopCallback onStop;
  final ActiveTimingStillTimingCallback? isRecordActivelyTiming;
  final void Function(String message)? onToast;

  @override
  State<_ActiveTimingReminderDialog> createState() => _ActiveTimingReminderDialogState();
}

class _ActiveTimingReminderDialogState extends State<_ActiveTimingReminderDialog> {
  late List<HistoryRecord> _rows;
  late Set<String> _selectedIds;
  Timer? _tickTimer;
  var _now = DateTime.now();
  var _stopping = false;

  bool get _multiSelect => _rows.length > 1;

  @override
  void initState() {
    super.initState();
    _rows = List<HistoryRecord>.from(widget.candidates);
    _selectedIds = _rows.map((r) => r.id).toSet();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    _closeDialog();
  }

  void _closeDialog() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool _recordStoppedAfterAttempt(String recordId, bool stopReturnedOk) {
    if (stopReturnedOk) return true;
    final stillTiming = widget.isRecordActivelyTiming;
    if (stillTiming == null) return false;
    return !stillTiming(recordId);
  }

  Future<void> _confirmStop() async {
    if (_stopping) return;
    final targets = _multiSelect
        ? _rows.where((r) => _selectedIds.contains(r.id)).toList()
        : _rows;
    if (targets.isEmpty) return;

    setState(() => _stopping = true);
    var failCount = 0;
    for (final record in targets) {
      final ok = await widget.onStop(record);
      if (!mounted) return;
      if (_recordStoppedAfterAttempt(record.id, ok)) {
        _rows.removeWhere((r) => r.id == record.id);
        _selectedIds.remove(record.id);
      } else {
        failCount++;
      }
    }

    if (!mounted) return;

    if (failCount > 0) {
      widget.onToast?.call('部分计时结束失败，请稍后重试');
      setState(() => _stopping = false);
      return;
    }

    // 所选记录全部停止成功即关闭（未勾选的其它计时可仍在后台继续）。
    _stopping = false;
    _closeDialog();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.55;
    final canConfirm = !_stopping && (!_multiSelect || _selectedIds.isNotEmpty);
    final confirmLabel = _multiSelect ? '结束所选' : '结束计时';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 340, maxHeight: maxH),
          child: Material(
            type: MaterialType.transparency,
            child: HistoryEditGlassPanel(
              onClose: _dismiss,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '还有计时未结束',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: glassText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '您刚新增了记录。以下事件仍在计时，可选择结束以免遗忘。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final record = _rows[index];
                        final eventDef = lookupEventForRecord(widget.eventCatalog, record);
                        final accent = resolveEventColor(context, eventDef);
                        final elapsed = formatActiveTimerElapsed(
                          _now.difference(activeTimingStartAt(record)),
                        );
                        final name = record.eventName.trim().isEmpty
                            ? '未知事件'
                            : record.eventName.trim();
                        final selected = _selectedIds.contains(record.id);

                        void toggleSelected() {
                          if (_stopping || !_multiSelect) return;
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(record.id);
                            } else {
                              _selectedIds.add(record.id);
                            }
                          });
                        }

                        return HistoryEditGlassTapField(
                          enabled: !_stopping,
                          minHeight: 56,
                          onTap: _multiSelect ? toggleSelected : null,
                          child: Row(
                            children: [
                              if (_multiSelect)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: selected,
                                    onChanged: _stopping
                                        ? null
                                        : (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selectedIds.add(record.id);
                                              } else {
                                                _selectedIds.remove(record.id);
                                              }
                                            });
                                          },
                                    activeColor: scheme.primary,
                                    checkColor: scheme.onPrimary,
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.45),
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              if (_multiSelect) const SizedBox(width: 8),
                              EventLogo(definition: eventDef, size: 28),
                              const SizedBox(width: 10),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: glassText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                elapsed,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: glassText.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _stopping ? null : _dismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: glassText.withValues(alpha: 0.88),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('暂不'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: canConfirm ? _confirmStop : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(_stopping ? '结束中…' : confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
