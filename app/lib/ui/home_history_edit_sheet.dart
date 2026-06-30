import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/event_remark_memory_store.dart';
import '../config/event_square_sync_preference_store.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_edit_media_item.dart';
import '../data/history_event_square_sync.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/models.dart';
import '../providers/home_history_notifier.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../ucg/data/ucg_album_picker.dart';
import '../ucg/data/ucg_location.dart';
import '../ucg/data/ucg_video_upload.dart';
import '../ucg/providers/ucg_providers.dart';
import 'event_logo.dart';
import 'history_event_media_picker.dart';
import 'home_event_number_picker.dart';
import 'home_history_edit_glass_panel.dart';
import 'home_history_time_wheel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/event_remark_quick_tags.dart';
import 'widgets/history_event_media_strip.dart';
import 'widgets/keyboard_dismiss_scope.dart';
import 'widgets/keyboard_input_bridge.dart';
import 'widgets/keyboard_lift.dart';

/// 主页历史行编辑：玻璃拟态底部 Sheet，返回 `true` 表示列表已变更。
Future<bool?> showHomeHistoryEditSheet(
  BuildContext context, {
  required HistoryRecord record,
  required List<EventDefinition> eventCatalog,
  required HomeHistoryNotifier history,
}) {
  return showGlassAdaptiveBottomSheet<bool>(
    context: context,
    maxHeightFraction: 4 / 5,
    enableDrag: false,
    wrapInGlassPanel: false,
    scrollable: false,
    respectKeyboardInset: true,
    bodyBuilder: (ctx) => _HomeHistoryEditSheetBody(
      recordId: record.id,
      eventCatalog: eventCatalog,
      history: history,
    ),
  );
}

class _HomeHistoryEditSheetBody extends ConsumerStatefulWidget {
  const _HomeHistoryEditSheetBody({
    required this.recordId,
    required this.eventCatalog,
    required this.history,
  });

  final String recordId;
  final List<EventDefinition> eventCatalog;
  final HomeHistoryNotifier history;

  @override
  ConsumerState<_HomeHistoryEditSheetBody> createState() => _HomeHistoryEditSheetBodyState();
}

class _HomeHistoryEditSheetBodyState extends ConsumerState<_HomeHistoryEditSheetBody> {
  final _remarkCtrl = TextEditingController();
  final _remarkFocusNode = FocusNode();
  final _remarkAnchorKey = GlobalKey();
  late FixedExtentScrollController _usagePickerCtrl;

  HistoryRecord? _record;
  DateTime _startEdit = DateTime.now();
  DateTime? _endEdit;
  var _saving = false;
  var _deleting = false;
  var _syncToSquare = false;
  var _loadingMedia = false;
  final _media = <HistoryEditMediaItem>[];

  @override
  void initState() {
    super.initState();
    _usagePickerCtrl = FixedExtentScrollController();
    _remarkFocusNode.addListener(_onRemarkFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRecord());
  }

  @override
  void dispose() {
    _remarkFocusNode.removeListener(_onRemarkFocusChange);
    _remarkFocusNode.dispose();
    _remarkCtrl.dispose();
    _usagePickerCtrl.dispose();
    super.dispose();
  }

  void _onRemarkTagSelected(String text) {
    _remarkCtrl.text = text;
    keyboardInputBridgeController.updateDraft(text);
    setState(() {});
  }

  void _onRemarkFocusChange() {
    handleBridgeFocusChange(
      context: context,
      focusNode: _remarkFocusNode,
      controller: _remarkCtrl,
      scene: 'home.history-edit.remark',
      onConfirm: () => _remarkFocusNode.unfocus(),
      hint: '备注',
      anchorKey: _remarkAnchorKey,
    );
  }

  void _resolveRecord() {
    final items = ref.read(homeHistoryProvider).items;
    final idx = items.indexWhere((e) => e.id == widget.recordId);
    if (idx < 0) {
      showAppToast('记录不存在', tone: AppToastTone.error);
      if (mounted) Navigator.pop(context);
      return;
    }
    final r = items[idx];
    setState(() {
      _record = r;
      _applyRecordToForm(r);
    });
    unawaited(_loadMediaAndSyncPref(r));
  }

  Future<void> _loadMediaAndSyncPref(HistoryRecord r) async {
    setState(() => _loadingMedia = true);
    final sync = await EventSquareSyncPreferenceStore.load(r.id);
    final media = await loadHistoryEditMediaItems(r);
    if (!mounted) return;
    setState(() {
      _media
        ..clear()
        ..addAll(media);
      _syncToSquare = media.isEmpty ? false : sync;
      _loadingMedia = false;
    });
  }

  void _applyRecordToForm(HistoryRecord r) {
    final p = r.rawPayload;
    _remarkCtrl.text = (p['remark'] as String?) ?? '';
    _startEdit = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    _endEdit = parseHistoryInstant(p['endTime']);
    final n = historyPayloadInt(p, 'eventNumber');
    if ((n == 1 || n > 1) && _endEdit == null) {
      _endEdit = _startEdit;
    }
    if (n > 1) {
      final usage = historyPayloadInt(p, 'eventNumber');
      final idx = HomeEventNumberPicker.indexForValue(usage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_usagePickerCtrl.hasClients) {
          _usagePickerCtrl.jumpToItem(idx);
        }
      });
    }
  }

  bool get _pending => _record != null && isPendingHistoryId(_record!.id);

  /// `eventNumber == 0`：改开始日期时若日历日晚于结束，仅同步结束日期（保留结束时/分）。
  void _onStartDateChanged(DateTime v) {
    setState(() {
      _startEdit = v;
      final end = _endEdit;
      if (end != null) {
        final startDay = homeHistoryDateOnly(v);
        final endDay = homeHistoryDateOnly(end);
        if (startDay.isAfter(endDay)) {
          _endEdit = DateTime(
            startDay.year,
            startDay.month,
            startDay.day,
            end.hour,
            end.minute,
          );
        }
      }
    });
  }

  /// `eventNumber == 0`：改开始时分后若整体晚于结束，将结束同步为开始时刻。
  void _onStartTimeChanged(DateTime v) {
    setState(() {
      _startEdit = v;
      final end = _endEdit;
      if (end != null && v.isAfter(end)) {
        _endEdit = v;
      }
    });
  }

  String _displayEventName(HistoryRecord r) {
    final e = r.eventName.trim();
    return e.isEmpty ? '未知事件' : e;
  }

  HistoryRecord _recordAfterLocalUpdate(
    HistoryRecord r, {
    required String remark,
    DateTime? startTime,
    DateTime? endTime,
    int? usageCount,
    bool clearEnd = false,
  }) {
    final p = Map<String, Object?>.from(r.rawPayload);
    p['remark'] = remark;
    if (startTime != null) {
      p['startTime'] = historyDateTimeToUnixSeconds(startTime);
    }
    if (endTime != null) {
      p['endTime'] = historyDateTimeToUnixSeconds(endTime);
    } else if (clearEnd) {
      p['endTime'] = 0;
    }
    if (usageCount != null) {
      p['eventNumber'] = usageCount;
    }
    final action = remark.trim().isEmpty ? '—' : remark.trim();
    return HistoryRecord(
      id: r.id,
      createdAt: r.createdAt,
      eventName: r.eventName,
      action: action,
      rawPayload: p,
    );
  }

  bool _isFormDirty() {
    final r = _record;
    if (r == null || _pending) return false;
    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final remark = (p['remark'] as String?) ?? '';
    if (_remarkCtrl.text != remark) return true;

    final start = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    final end = parseHistoryInstant(p['endTime']);
    final endUnset = historyInstantUnset(end);

    if (n == 0) {
      if (_startEdit != start) return true;
      if (endUnset) {
        if (_endEdit != null) return true;
      } else if (end != null && (_endEdit == null || _endEdit != end)) {
        return true;
      }
      return false;
    }

    final endCompare = end ?? start;
    if (_endEdit == null || _endEdit != endCompare) return true;
    if (n > 1) {
      final usage = historyPayloadInt(p, 'eventNumber');
      final idx = _usagePickerCtrl.hasClients ? _usagePickerCtrl.selectedItem : 0;
      final picked = HomeEventNumberPicker.valueAtIndex(idx);
      if (picked != usage) return true;
    }
    return false;
  }

  Future<bool> _confirmDiscardEdits() async {
    return await showGlassConfirmDialog(
          context,
          title: '放弃修改？',
          message: '未保存的修改将丢失。',
          cancelLabel: '继续编辑',
          confirmLabel: '放弃',
        ) ??
        false;
  }

  Future<bool> _onMaybePop() async {
    if (!_isFormDirty()) return true;
    return _confirmDiscardEdits();
  }

  Future<void> _requestClose() async {
    if (!await _onMaybePop()) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _save() async {
    final r = _record;
    if (r == null || _pending || _saving) return;
    if (!validateHistoryEditMedia(_media)) {
      showAppToast('最多 9 张图片或 1 条视频', tone: AppToastTone.error);
      return;
    }
    final n = historyPayloadInt(r.rawPayload, 'eventNumber');
    final repo = ref.read(feedRepositoryProvider);
    final remark = _remarkCtrl.text.trim();
    final existingPostId = historyPayloadPostId(r.rawPayload);

    setState(() => _saving = true);
    HistoryRecord? updated;
    var ok = false;
    DateTime? saveStart;
    DateTime? saveEnd;
    int? saveUsage;

    if (n == 0) {
      if (_endEdit != null && _endEdit!.isBefore(_startEdit)) {
        showAppToast('结束时间不能早于开始时间', tone: AppToastTone.error);
        setState(() => _saving = false);
        return;
      }
      saveStart = _startEdit;
      saveEnd = _endEdit;
    } else if (n == 1) {
      if (_endEdit == null) {
        showAppToast('请选择结束时间', tone: AppToastTone.error);
        setState(() => _saving = false);
        return;
      }
      saveStart = _endEdit;
      saveEnd = _endEdit;
    } else {
      if (_endEdit == null) {
        showAppToast('请选择结束时间', tone: AppToastTone.error);
        setState(() => _saving = false);
        return;
      }
      final idx = _usagePickerCtrl.hasClients ? _usagePickerCtrl.selectedItem : 0;
      saveUsage = HomeEventNumberPicker.valueAtIndex(idx);
      saveStart = _endEdit;
      saveEnd = _endEdit;
    }

    ok = await repo.updateHistoryRecord(
      r.id,
      remark: remark,
      startTime: saveStart,
      endTime: saveEnd,
      usageCount: saveUsage,
      clearEndIfNull: n == 0,
      fallbackRecord: r,
    );

    if (ok) {
      final syncEnabled = _effectiveSyncToSquare;
      UcgCoords? syncCoords;
      if (syncEnabled && _media.isNotEmpty) {
        syncCoords = await ensureUcgLocationForDistance(context, ref);
      }
      final baby = await ref.read(settingsBabyProvider.future);
      final eventDef = lookupEventForRecord(widget.eventCatalog, r);
      final syncEventName = (eventDef?.name ?? r.eventName).trim();
      final syncResult = await runHistoryEventMediaSideEffects(
        ucgRepo: ref.read(ucgRepositoryProvider),
        wxId: ref.read(ucgCurrentUserIdProvider),
        historyId: r.id,
        babyNickname: baby.nickname,
        eventName: syncEventName,
        remark: remark,
        media: List.unmodifiable(_media),
        syncEnabled: syncEnabled,
        existingPostId: existingPostId,
        lat: syncCoords?.lat,
        lng: syncCoords?.lng,
      );

      if (syncResult.skippedUcg) {
        showAppToast('请先绑定微信账号后再同步广场', tone: AppToastTone.info);
      } else if (syncResult.videoUploadSkipped) {
        showAppToast(kUcgVideoUploadDisabledMessage, tone: AppToastTone.info);
      } else if (syncResult.ucgError != null) {
        showAppToast('媒体同步失败，历史已保存', tone: AppToastTone.info);
      }

      await repo.updateHistoryRecord(
        r.id,
        remark: remark,
        startTime: saveStart,
        endTime: saveEnd,
        usageCount: saveUsage,
        clearEndIfNull: n == 0,
        fallbackRecord: r,
        postId: syncResult.postId,
        mediaType: syncResult.mediaType,
        imageKeys: syncResult.imageKeys,
        videoKey: syncResult.videoKey,
        patchMediaFields: true,
      );

      updated = _recordAfterLocalUpdate(
        r,
        remark: remark,
        startTime: saveStart,
        endTime: saveEnd,
        usageCount: saveUsage,
        clearEnd: n == 0 && saveEnd == null,
      );
      updated = applyMediaFieldsToRecord(
        updated,
        postId: syncResult.postId,
        mediaType: syncResult.mediaType,
        imageKeys: syncResult.imageKeys,
        videoKey: syncResult.videoKey,
      );

      if (syncEnabled && syncResult.postId > 0) {
        ref.read(ucgPostsChangedProvider.notifier).update((n) => n + 1);
      } else if (!syncEnabled && existingPostId > 0) {
        ref.read(ucgPostsChangedProvider.notifier).update((n) => n + 1);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok || updated == null) return;
    unawaited(EventRemarkMemoryStore.save(historyRecordEventId(r), remark));
    unawaited(EventSquareSyncPreferenceStore.save(r.id, _effectiveSyncToSquare));
    widget.history.replaceRecord(updated);
    showAppToast('已保存', tone: AppToastTone.success);
    Navigator.pop(context, true);
  }

  Future<void> _pickMedia() async {
    final r = _record;
    if (r == null || _pending || _saving) return;
    try {
      final picked = await pickHistoryEventMedia(
        context: context,
        repo: ref.read(ucgRepositoryProvider),
        current: _media,
      );
      if (picked == null || picked.isEmpty || !mounted) return;
      final current = List<HistoryEditMediaItem>.from(_media);
      setState(() {
        _media
          ..clear()
          ..addAll(mergeHistoryPickedMedia(current: current, picked: picked));
      });
    } on UcgAlbumMixedMediaException {
      showAppToast('不能同时选择图片和视频', tone: AppToastTone.error);
    }
  }

  void _removeMediaAt(int index) {
    if (index < 0 || index >= _media.length) return;
    setState(() {
      _media.removeAt(index);
      if (_media.isEmpty) _syncToSquare = false;
    });
  }

  void _reorderMedia(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= _media.length || to >= _media.length) return;
    setState(() {
      final item = _media.removeAt(from);
      _media.insert(to, item);
    });
  }

  bool get _canAddMedia {
    if (_pending) return false;
    if (_media.any((e) => e.isVideo)) return false;
    if (_media.where((e) => e.isImage).length >= 9) return false;
    return true;
  }

  bool get _effectiveSyncToSquare => _syncToSquare && _media.isNotEmpty;

  Future<void> _confirmDelete() async {
    final r = _record;
    if (r == null || _pending || _deleting) return;
    final go = await showGlassConfirmDialog(
          context,
          title: '删除事件',
          message: '确定删除该条历史记录？此操作不可撤销。',
          confirmLabel: '删除',
        ) ??
        false;
    if (!go || !mounted) return;
    setState(() => _deleting = true);
    final ok = await ref.read(feedRepositoryProvider).deleteHistoryRecord(r.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (!ok) return;
    widget.history.removeRecord(r.id);
    showAppToast('已删除', tone: AppToastTone.success);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final r = _record;
    if (r == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final unit = (p['eventUnit'] as String?)?.trim() ?? '';
    final eventDef = lookupEventForRecord(widget.eventCatalog, r);
    final accent = resolveEventColor(context, eventDef);
    final readOnly = _pending;
    final scheme = Theme.of(context).colorScheme;
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);

    final startAnchor = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    final endAnchor = _endEdit ?? parseHistoryInstant(p['endTime']) ?? startAnchor;
    final now = DateTime.now();
    final pickerMaxDate = homeHistoryDateOnly(now);
    final babyAsync = ref.watch(settingsBabyProvider);
    final pickerMinDate = babyAsync.maybeWhen(
      data: (baby) => homeHistoryDateOnly(baby.birthDate),
      orElse: () => DateTime(2000, 1, 1),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestClose();
      },
      child: HistoryEditGlassPanel(
        eventAccent: accent,
        onClose: _requestClose,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (readOnly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '同步中…',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.primary.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Center(child: EventLogo(definition: eventDef, size: 44)),
                    const SizedBox(height: 10),
                    Text(
                      _displayEventName(r),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: glassText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (n == 0) ...[
                      HomeHistoryDateTimeRow(
                        label: '开始时间',
                        minimumDate: pickerMinDate,
                        maximumDate: pickerMaxDate,
                        anchorDate: startAnchor,
                        value: _startEdit,
                        enabled: !readOnly,
                        onDateChanged: _onStartDateChanged,
                        onTimeChanged: _onStartTimeChanged,
                      ),
                      const SizedBox(height: 14),
                      HomeHistoryDateTimeRow(
                        label: '结束时间',
                        minimumDate: pickerMinDate,
                        maximumDate: pickerMaxDate,
                        anchorDate: endAnchor,
                        value: _endEdit,
                        enabled: !readOnly,
                        onChanged: (v) => setState(() => _endEdit = v),
                      ),
                      if (!readOnly && _endEdit != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _endEdit = null),
                            style: TextButton.styleFrom(
                              foregroundColor: glassLabel,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: const Text('清除结束时间'),
                          ),
                        ),
                    ] else ...[
                      HomeHistoryDateTimeRow(
                        label: '结束时间',
                        minimumDate: pickerMinDate,
                        maximumDate: pickerMaxDate,
                        anchorDate: endAnchor,
                        value: _endEdit,
                        enabled: !readOnly,
                        onChanged: (v) => setState(() => _endEdit = v),
                      ),
                    ],
                    if (n > 1) ...[
                      const SizedBox(height: 14),
                      Text(
                        '用量${unit.isNotEmpty ? '（$unit）' : ''}',
                        style: TextStyle(fontSize: 13, color: glassLabel),
                      ),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: CupertinoTheme(
                          data: const CupertinoThemeData(brightness: Brightness.dark),
                          child: HomeEventNumberPicker(
                            controller: _usagePickerCtrl,
                            enabled: !readOnly,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    KeyboardDismissExclude(
                      child: EventRemarkQuickTags(
                        eventId: historyRecordEventId(r),
                        onSelect: _onRemarkTagSelected,
                        padding: const EdgeInsets.only(bottom: 8),
                      ),
                    ),
                    keyboardLiftTarget(
                      focusNode: _remarkFocusNode,
                      anchorKey: _remarkAnchorKey,
                      child: TextField(
                        controller: _remarkCtrl,
                        focusNode: _remarkFocusNode,
                        readOnly: readOnly,
                        style: TextStyle(color: glassText, fontSize: 15),
                        cursorColor: scheme.primary,
                        decoration: historyEditGlassInputDecoration(context, labelText: '备注').copyWith(
                          suffixIcon: !readOnly && _canAddMedia
                              ? IconButton(
                                  onPressed: _saving ? null : () => unawaited(_pickMedia()),
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: glassLabel,
                                  ),
                                  tooltip: '添加图片或视频',
                                )
                              : null,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: readOnly ? null : keyboardInputBridgeController.updateDraft,
                        onSubmitted: readOnly ? null : (_) => FocusScope.of(context).unfocus(),
                        maxLines: 1,
                      ),
                    ),
                    if (_loadingMedia)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else if (_media.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      HistoryEventMediaStrip(
                        items: _media,
                        enabled: !readOnly,
                        onReorder: _reorderMedia,
                        onRemoveAt: _removeMediaAt,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!readOnly)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _deleting ? null : _confirmDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error.withValues(alpha: 0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(_deleting ? '删除中…' : '删除'),
                    ),
                    const Spacer(),
                    if (_media.isNotEmpty) ...[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Transform.scale(
                              scale: 0.78,
                              child: Switch(
                                value: _effectiveSyncToSquare,
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() => _syncToSquare = v),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -4),
                            child: Text(
                              '同步广场',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1,
                                color: glassLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(_saving ? '保存中…' : '保存'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
