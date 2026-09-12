import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../home_widget/format_widget_relative_time.dart';
import '../theme/app_color.dart';
import 'event_logo.dart';
import 'home_event_number_picker.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

/// recall / per-card 间隔滚轮选项（15 分钟步进，最长 24 小时）。
List<int> recallIntervalMinuteChoices() => [
      for (var m = 15; m <= 24 * 60; m += 15) m,
    ];

/// 间隔分钟数 → 展示文案。
String formatRecallIntervalMinutes(int minutes) {
  if (minutes < 60) return '$minutes 分钟';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '$h 小时';
  return '$h 小时 $m 分钟';
}

/// 弹出间隔 Sheet：选滚轮 → 确认写种子（[onCommit]）→ 同层思考打字机 → 关闭返回分钟数。
/// 取消 / 遮罩关闭返回 null。[onCommit] 返回 false 时停留在选间隔态。
Future<int?> pickRecallIntervalMinutes(
  BuildContext context, {
  EventDefinition? definition,
  String? eventName,
  required DateTime lastAt,
  int initialMinutes = 180,
  required Future<bool> Function(int minutes) onCommit,
}) async {
  final items = recallIntervalMinuteChoices();
  var idx = items.indexOf(initialMinutes);
  if (idx < 0) idx = items.indexOf(180).clamp(0, items.length - 1);
  final name = (eventName?.trim().isNotEmpty == true)
      ? eventName!.trim()
      : (definition?.name.trim().isNotEmpty == true
          ? definition!.name.trim()
          : '事件');
  return showGlassAdaptiveBottomSheet<int>(
    context: context,
    scrollable: false,
    bodyBuilder: (ctx) => _RecallIntervalThinkingSheetBody(
      definition: definition,
      eventName: name,
      lastAt: lastAt,
      items: items,
      initialIndex: idx,
      onCommit: onCommit,
    ),
  );
}

enum _SheetPhase { picking, thinking }

class _RecallIntervalThinkingSheetBody extends StatefulWidget {
  const _RecallIntervalThinkingSheetBody({
    required this.definition,
    required this.eventName,
    required this.lastAt,
    required this.items,
    required this.initialIndex,
    required this.onCommit,
  });

  final EventDefinition? definition;
  final String eventName;
  final DateTime lastAt;
  final List<int> items;
  final int initialIndex;
  final Future<bool> Function(int minutes) onCommit;

  @override
  State<_RecallIntervalThinkingSheetBody> createState() =>
      _RecallIntervalThinkingSheetBodyState();
}

class _RecallIntervalThinkingSheetBodyState
    extends State<_RecallIntervalThinkingSheetBody> {
  late FixedExtentScrollController _ctrl;
  late int _index;
  var _phase = _SheetPhase.picking;
  var _committing = false;
  var _committedMinutes = 0;

  /// 主段叙事（逐字）。
  var _mainFull = '';
  var _mainVisible = 0;

  /// 主段打完后展示的加粗说明。
  static const _boldFooter =
      '随着后续的喂养节奏，我会自动修改预测时间；当前只是为了适应还没有足够喂养信息的时候。';
  var _showBold = false;

  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _ctrl = FixedExtentScrollController(initialItem: _index);
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  bool get _mainDone =>
      _mainFull.isNotEmpty && _mainVisible >= _mainFull.length;

  bool get _thinkingComplete => _mainDone && _showBold;

  DateTime get _estimatedNextAt =>
      widget.lastAt.add(Duration(minutes: _committedMinutes));

  void _cancelPick() => Navigator.pop(context);

  void _closeAfterThinking() =>
      Navigator.pop(context, _committedMinutes);

  Future<void> _onConfirmPick() async {
    if (_committing) return;
    final minutes = widget.items[_index];
    if (minutes < kMinIntervalForPrediction.inMinutes) {
      showAppToast('间隔至少 15 分钟', tone: AppToastTone.error);
      return;
    }
    setState(() => _committing = true);
    try {
      final ok = await widget.onCommit(minutes);
      if (!mounted) return;
      if (!ok) {
        setState(() => _committing = false);
        return;
      }
      _committedMinutes = minutes;
      final intervalLabel = formatRecallIntervalMinutes(minutes);
      _mainFull =
          '好的，我记下了「${widget.eventName}」大概每 $intervalLabel 一次。'
          '正在按你的节奏合成推演样本，为「${widget.eventName}」量身定做智能预测…';
      _mainVisible = 0;
      _showBold = false;
      setState(() {
        _phase = _SheetPhase.thinking;
        _committing = false;
      });
      _startTypewriter();
    } catch (_) {
      if (mounted) setState(() => _committing = false);
      rethrow;
    }
  }

  void _startTypewriter() {
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 42), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_mainVisible < _mainFull.length) {
        setState(() => _mainVisible++);
        return;
      }
      t.cancel();
      if (!_showBold) setState(() => _showBold = true);
    });
  }

  void _skipThinkingAnimation() {
    _typeTimer?.cancel();
    setState(() {
      _mainVisible = _mainFull.length;
      _showBold = true;
    });
  }

  /// 同层回到选间隔，便于改间隔再确认。
  void _backToPicking() {
    _typeTimer?.cancel();
    final idx = widget.items.indexOf(_committedMinutes);
    final nextIndex =
        (idx >= 0 ? idx : _index).clamp(0, widget.items.length - 1);
    _ctrl.dispose();
    _ctrl = FixedExtentScrollController(initialItem: nextIndex);
    setState(() {
      _index = nextIndex;
      _phase = _SheetPhase.picking;
      _mainFull = '';
      _mainVisible = 0;
      _showBold = false;
      _committing = false;
    });
  }

  Widget _buildTitle(Color onSheet) {
    final logo = widget.definition;
    if (_phase == _SheetPhase.picking) {
      final title = logo != null
          ? '${widget.eventName}·大概多久一次'
          : '大概多久一次';
      return _titleRow(onSheet, title, logo);
    }
    final intervalLabel = formatRecallIntervalMinutes(_committedMinutes);
    return _titleRow(onSheet, '大概 $intervalLabel 一次', logo);
  }

  Widget _titleRow(Color onSheet, String title, EventDefinition? logo) {
    if (logo == null) {
      return Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: onSheet),
        textAlign: TextAlign.center,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        EventLogo(definition: logo, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onSheet,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingStatus(Color primary) {
    if (!_thinkingComplete) {
      return Text(
        '正在思考…',
        style: TextStyle(
          fontSize: 13,
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final when = formatWidgetLastAt(_estimatedNextAt, DateTime.now());
    final label = '思考完毕 · 下一次${widget.eventName}：$when发生';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _backToPicking,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: primary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColor.primary(context);
    final onPrimary = AppColor.onPrimary(context);
    final onSheet = historyEditGlassTextColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitle(onSheet),
          const SizedBox(height: 8),
          if (_phase == _SheetPhase.picking) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.fieldBorder(context)),
                color: AppColor.fieldFill(context),
              ),
              child: SizedBox(
                height: kHomeEventNumberPickerHeight,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    primaryColor: primary,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: onSheet,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController: _ctrl,
                    itemExtent: kHomeEventNumberPickerItemExtent,
                    onSelectedItemChanged: (i) => _index = i,
                    selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                      background: primary.withValues(alpha: 0.12),
                    ),
                    children: [
                      for (final m in widget.items)
                        Center(
                          child: Text(
                            formatRecallIntervalMinutes(m),
                            style: TextStyle(color: onSheet),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _committing ? null : _cancelPick,
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: onPrimary,
                    ),
                    onPressed:
                        _committing ? null : () => unawaited(_onConfirmPick()),
                    child: Text(_committing ? '提交中…' : '确定'),
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildThinkingStatus(primary),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _mainFull.substring(0, _mainVisible),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.55,
                        color: onSheet.withValues(alpha: 0.88),
                      ),
                    ),
                    if (_showBold) ...[
                      const SizedBox(height: 12),
                      Text(
                        _boldFooter,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                          color: onSheet,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: onPrimary,
              ),
              onPressed: _thinkingComplete
                  ? _closeAfterThinking
                  : _skipThinkingAnimation,
              child: Text(_thinkingComplete ? '关闭' : '跳过动画'),
            ),
          ],
        ],
      ),
    );
  }
}
