import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/prediction_recall_seed.dart';
import '../providers/forecast_toggle_provider.dart';
import '../providers/prediction_recall_provider.dart';
import '../theme/app_color.dart';
import 'widgets/app_modal_glass_panel.dart';
import 'widgets/app_toast.dart';

/// 智能预测页内嵌：悬浮卡 PageView（禁手滑）+ 逐卡思考 + 收尾 CTA。
class PredictionRecallOnboardingPanel extends ConsumerStatefulWidget {
  const PredictionRecallOnboardingPanel({
    super.key,
    required this.gapRoots,
    required this.catalog,
    required this.onFinished,
  });

  final List<EventDefinition> gapRoots;
  final List<EventDefinition> catalog;
  final VoidCallback onFinished;

  @override
  ConsumerState<PredictionRecallOnboardingPanel> createState() =>
      _PredictionRecallOnboardingPanelState();
}

class _PredictionRecallOnboardingPanelState
    extends ConsumerState<PredictionRecallOnboardingPanel> {
  static final _timeFmt = DateFormat('M月d日 HH:mm');

  late List<EventDefinition> _queue;
  late final PageController _pageController;
  var _pageIndex = 0;

  /// 思考盖在当前卡上，不单独占 PageView 页（避免手滑语义混乱）。
  var _showThinking = false;

  late DateTime _lastAt;
  var _intervalMinutes = 180;
  String? _leafId;
  String _thinkingFull = '';
  var _thinkingVisible = 0;
  Timer? _typeTimer;

  /// 页数 = 各根卡片 + 收尾页。
  int get _pageCount => _queue.isEmpty ? 1 : _queue.length + 1;

  bool get _isFinalePage => _pageIndex >= _queue.length;

  EventDefinition? get _current {
    if (_queue.isEmpty || _pageIndex < 0 || _pageIndex >= _queue.length) {
      return null;
    }
    return _queue[_pageIndex];
  }

  @override
  void initState() {
    super.initState();
    _queue = List<EventDefinition>.from(widget.gapRoots);
    _pageController = PageController();
    _resetCardDefaults();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<EventDefinition> _leafChoices(EventDefinition root) {
    final kids = childrenOf(widget.catalog, root.id);
    if (kids.isEmpty) return [root];
    return kids;
  }

  void _resetCardDefaults() {
    final now = DateTime.now();
    _lastAt = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _intervalMinutes = 180;
    final root = _current;
    if (root == null) {
      _leafId = null;
      return;
    }
    final leaves = _leafChoices(root);
    _leafId = leaves.first.id;
  }

  Future<void> _goToPage(int page) async {
    if (!_pageController.hasClients) {
      setState(() => _pageIndex = page);
      return;
    }
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (mounted) {
      setState(() {
        _pageIndex = page;
        _resetCardDefaults();
      });
    }
  }

  Future<void> _onSkip() async {
    final root = _current;
    if (root == null) return;
    await ref
        .read(forecastDisabledIdsProvider.notifier)
        .setEnabled(root.id, false);
    if (!mounted) return;
    showAppToast('已跳过，暂不预测「${root.name}」');
    await _advanceToNextRoot();
  }

  Future<void> _onConfirm() async {
    final root = _current;
    if (root == null) return;
    final leafId = _leafId ?? root.id;
    final interval = Duration(minutes: _intervalMinutes);
    if (interval < kMinIntervalForPrediction) {
      showAppToast('间隔至少 15 分钟', tone: AppToastTone.error);
      return;
    }
    final seed = PredictionRecallSeed(
      rootEventId: root.id,
      leafEventId: leafId,
      lastAt: _lastAt,
      interval: interval,
      occurrenceAts:
          synthesizeOccurrenceAts(lastAt: _lastAt, interval: interval),
    );
    await ref.read(predictionRecallSeedsProvider.notifier).upsertSeed(seed);
    if (!mounted) return;

    final leaf = lookupLeafName(leafId, root);
    final isTime = root.parsedEventType == EventCatalogEventType.time;
    final whenLabel = isTime ? '上次结束' : '上次发生';
    _thinkingFull =
        '好的，我记下了「${root.name}」：$whenLabel在 ${_timeFmt.format(_lastAt)}，'
        '大概每 ${_formatInterval(_intervalMinutes)} 一次'
        '${leaf != root.name ? '，具体是「$leaf」' : ''}。'
        '正在按你的节奏合成推演样本，为「${root.name}」量身定做智能预测…';
    _thinkingVisible = 0;
    setState(() => _showThinking = true);
    _startTypewriter();
  }

  String lookupLeafName(String leafId, EventDefinition root) {
    for (final e in widget.catalog) {
      if (catalogIdsEqual(e.id, leafId)) {
        return e.name.trim().isEmpty ? root.name : e.name.trim();
      }
    }
    return root.name;
  }

  String _formatInterval(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h 小时';
    return '$h 小时 $m 分钟';
  }

  void _startTypewriter() {
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 42), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_thinkingVisible >= _thinkingFull.length) {
        t.cancel();
        return;
      }
      setState(() => _thinkingVisible++);
    });
  }

  Future<void> _advanceToNextRoot() async {
    _typeTimer?.cancel();
    setState(() => _showThinking = false);
    final next = _pageIndex + 1;
    await _goToPage(next.clamp(0, _pageCount - 1));
  }

  Future<void> _onThinkingContinue() async {
    if (_thinkingVisible < _thinkingFull.length) {
      _typeTimer?.cancel();
      setState(() => _thinkingVisible = _thinkingFull.length);
      return;
    }
    await _advanceToNextRoot();
  }

  Future<void> _pickLastAt() async {
    final root = _current;
    final isTime = root?.parsedEventType == EventCatalogEventType.time;
    var temp = _lastAt;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  Text(isTime ? '上次结束时间' : '上次发生时间'),
                  CupertinoButton(
                    child: const Text('确定'),
                    onPressed: () {
                      setState(() => _lastAt = temp);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                use24hFormat: true,
                minuteInterval: 1,
                initialDateTime: _lastAt,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (v) => temp = v,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickInterval() async {
    final items = <int>[
      for (var m = 15; m <= 12 * 60; m += 15) m,
    ];
    var idx = items.indexOf(_intervalMinutes);
    if (idx < 0) idx = items.indexOf(180).clamp(0, items.length - 1);
    var tempIdx = idx;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  const Text('大概多久一次'),
                  CupertinoButton(
                    child: const Text('确定'),
                    onPressed: () {
                      setState(() => _intervalMinutes = items[tempIdx]);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController:
                    FixedExtentScrollController(initialItem: idx),
                onSelectedItemChanged: (i) => tempIdx = i,
                children: [
                  for (final m in items)
                    Center(child: Text(_formatInterval(m))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 浮层内文案跟 modal 前景原子
    final onShell = AppColor.textOnModal(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            // 禁止用户左右拖滑；仅确认/跳过/继续程序切页
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pageCount,
            onPageChanged: (i) {
              setState(() {
                _pageIndex = i;
                if (!_isFinalePage) _resetCardDefaults();
              });
            },
            itemBuilder: (context, index) {
              if (index >= _queue.length) {
                return _FloatingCard(
                  child: _buildFinaleBody(onShell, scheme),
                );
              }
              return _FloatingCard(
                child: _buildCardBody(
                  onShell,
                  scheme,
                  root: _queue[index],
                  progress: '${index + 1}/${_queue.length}',
                  active: index == _pageIndex && !_showThinking,
                ),
              );
            },
          ),
          if (_showThinking && !_isFinalePage)
            Positioned.fill(
              child: _FloatingCard(
                child: _buildThinkingBody(onShell, scheme),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardBody(
    Color onShell,
    ColorScheme scheme, {
    required EventDefinition root,
    required String progress,
    required bool active,
  }) {
    final isTime = root.parsedEventType == EventCatalogEventType.time;
    final leaves = _leafChoices(root);
    final selectedLeaf = active
        ? _leafId
        : (leaves.isNotEmpty ? leaves.first.id : root.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '为宝宝量身定做 · $progress',
          style: TextStyle(
            fontSize: 13,
            color: onShell.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          root.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: onShell,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTime ? '还记得上次结束是什么时候吗？' : '还记得上次发生是什么时候吗？',
          style: TextStyle(
            fontSize: 15,
            color: onShell.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 16),
        _SelectTile(
          label: isTime ? '上次结束时间' : '上次发生时间',
          value: _timeFmt.format(active ? _lastAt : DateTime.now()),
          onTap: active ? () => unawaited(_pickLastAt()) : () {},
        ),
        const SizedBox(height: 10),
        _SelectTile(
          label: '大概多久一次',
          value: _formatInterval(active ? _intervalMinutes : 180),
          onTap: active ? () => unawaited(_pickInterval()) : () {},
        ),
        const SizedBox(height: 14),
        Text(
          '当时是哪一种？',
          style: TextStyle(
            fontSize: 13,
            color: onShell.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final leaf in leaves)
              ChoiceChip(
                label: Text(leaf.name),
                selected: selectedLeaf != null &&
                    catalogIdsEqual(selectedLeaf, leaf.id),
                onSelected: active
                    ? (_) => setState(() => _leafId = leaf.id)
                    : null,
              ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(
              onPressed: active ? () => unawaited(_onSkip()) : null,
              child: const Text('跳过此事件'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: active ? () => unawaited(_onConfirm()) : null,
              child: const Text('确认'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThinkingBody(Color onShell, ColorScheme scheme) {
    final text = _thinkingFull.substring(0, _thinkingVisible);
    final done = _thinkingVisible >= _thinkingFull.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '正在思考…',
          style: TextStyle(
            fontSize: 13,
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: onShell.withValues(alpha: 0.88),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => unawaited(_onThinkingContinue()),
          child: Text(done ? '继续' : '跳过动画'),
        ),
      ],
    );
  }

  Widget _buildFinaleBody(Color onShell, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(Icons.auto_awesome, size: 40, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          '已按你的情况准备好智能预测',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onShell,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '本地算法会结合回忆节奏持续学习；之后的真实喂养记录会让预测更准。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: onShell.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: widget.onFinished,
          child: const Text('体验胖宝智能预测'),
        ),
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 召回浮层外壳与登录/绑定引导同源 modal 原子
    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      color: Colors.transparent,
      child: AppModalGlassPanel(
        borderRadius: 24,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: child,
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.unfold_more, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
