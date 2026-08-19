import 'dart:async';

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
import 'event_logo.dart';
import 'glass_single_wheel_picker_sheet.dart';
import 'home_history_time_wheel.dart';
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

/// 单根事件卡的会话草稿：当前值 + 首次进入时的默认快照。
class _RecallCardDraft {
  _RecallCardDraft({
    required this.lastAt,
    required this.intervalMinutes,
    required this.baselineLastAt,
    required this.baselineInterval,
  });

  DateTime lastAt;
  int intervalMinutes;
  final DateTime baselineLastAt;
  final int baselineInterval;

  /// 上次时刻到分钟，或间隔，相对首次默认有一项不同即算改过。
  bool get isDirty =>
      !_sameMinute(lastAt, baselineLastAt) || intervalMinutes != baselineInterval;
}

bool _sameMinute(DateTime a, DateTime b) =>
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day &&
    a.hour == b.hour &&
    a.minute == b.minute;

class _PredictionRecallOnboardingPanelState
    extends ConsumerState<PredictionRecallOnboardingPanel> {
  static final _timeFmt = DateFormat('M月d日 HH:mm');

  late List<EventDefinition> _queue;
  late final PageController _pageController;
  var _pageIndex = 0;

  /// 思考盖在当前卡上，不单独占 PageView 页（避免手滑语义混乱）。
  var _showThinking = false;

  /// 按根 id 缓存草稿；首次进入才写入默认，切页不得覆盖。
  final _drafts = <String, _RecallCardDraft>{};

  /// 未改表单点确认时，在确认钮上方展示「请认真回忆事件」。
  var _showRecallHint = false;

  String _thinkingFull = '';
  var _thinkingVisible = 0;
  Timer? _typeTimer;
  Timer? _autoAdvanceTimer;

  DateTime get _lastAt {
    final root = _current;
    if (root == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, now.hour, now.minute);
    }
    return _draftFor(root.id).lastAt;
  }

  int get _intervalMinutes {
    final root = _current;
    if (root == null) return 180;
    return _draftFor(root.id).intervalMinutes;
  }

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
    // 首张卡写入默认草稿与快照。
    _ensureCurrentDraft();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// 真实子事件；空则不展示「该事件包含」。
  List<EventDefinition> _childEvents(EventDefinition root) =>
      childrenOf(widget.catalog, root.id);

  /// 首次进入该根才写入此刻+180；已有草稿原样返回。
  _RecallCardDraft _draftFor(String rootId) {
    return _drafts.putIfAbsent(rootId, () {
      final now = DateTime.now();
      final t = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      return _RecallCardDraft(
        lastAt: t,
        intervalMinutes: 180,
        baselineLastAt: t,
        baselineInterval: 180,
      );
    });
  }

  void _ensureCurrentDraft() {
    final root = _current;
    if (root == null) return;
    _draftFor(root.id);
  }

  Future<void> _goToPage(int page) async {
    if (!_pageController.hasClients) {
      setState(() {
        _pageIndex = page;
        _showRecallHint = false;
        _ensureCurrentDraft();
      });
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
        _showRecallHint = false;
        _ensureCurrentDraft();
      });
    }
  }

  /// 回到上一张表单；思考中 / 首张 / 收尾不得调用。
  Future<void> _onBack() async {
    if (_showThinking || _isFinalePage || _pageIndex <= 0) return;
    await _goToPage(_pageIndex - 1);
  }

  Future<void> _onSkip() async {
    final root = _current;
    if (root == null) return;
    // 先反馈并翻页；开关持久化后台跑，避免 prefs 卡住像「点了没反应」
    showAppToast('已跳过，暂不预测「${root.name}」');
    unawaited(
      ref.read(forecastDisabledIdsProvider.notifier).setEnabled(root.id, false),
    );
    await _advanceToNextRoot();
  }

  Future<void> _onConfirm() async {
    final root = _current;
    if (root == null) return;
    final draft = _draftFor(root.id);
    // 未改过默认快照：拦截写种子，红字提示认真回忆。
    if (!draft.isDirty) {
      setState(() => _showRecallHint = true);
      return;
    }
    final interval = Duration(minutes: draft.intervalMinutes);
    if (interval < kMinIntervalForPrediction) {
      showAppToast('间隔至少 15 分钟', tone: AppToastTone.error);
      return;
    }
    // 不再选叶：种子挂根事件
    final seed = PredictionRecallSeed(
      rootEventId: root.id,
      leafEventId: root.id,
      lastAt: draft.lastAt,
      interval: interval,
      occurrenceAts:
          synthesizeOccurrenceAts(lastAt: draft.lastAt, interval: interval),
    );
    await ref.read(predictionRecallSeedsProvider.notifier).upsertSeed(seed);
    if (!mounted) return;
    // 先跳过再回来确认时，必须重新打开该根推演。
    unawaited(
      ref.read(forecastDisabledIdsProvider.notifier).setEnabled(root.id, true),
    );

    final isTime = root.parsedEventType == EventCatalogEventType.time;
    final whenLabel = isTime ? '上次结束' : '上次发生';
    _thinkingFull =
        '好的，我记下了「${root.name}」：$whenLabel在 ${_timeFmt.format(draft.lastAt)}，'
        '大概每 ${_formatInterval(draft.intervalMinutes)} 一次。'
        '正在按你的节奏合成推演样本，为「${root.name}」量身定做智能预测…';
    _thinkingVisible = 0;
    setState(() {
      _showThinking = true;
      _showRecallHint = false;
    });
    _startTypewriter();
  }

  String _formatInterval(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h 小时';
    return '$h 小时 $m 分钟';
  }

  void _scheduleAutoAdvanceAfterThinking() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || !_showThinking) return;
      unawaited(_advanceToNextRoot());
    });
  }

  void _startTypewriter() {
    _typeTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 42), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_thinkingVisible >= _thinkingFull.length) {
        t.cancel();
        _scheduleAutoAdvanceAfterThinking();
        return;
      }
      setState(() => _thinkingVisible++);
      if (_thinkingVisible >= _thinkingFull.length) {
        t.cancel();
        _scheduleAutoAdvanceAfterThinking();
      }
    });
  }

  Future<void> _advanceToNextRoot() async {
    _typeTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    setState(() => _showThinking = false);
    final next = _pageIndex + 1;
    await _goToPage(next.clamp(0, _pageCount - 1));
  }

  /// 跳过打字机；全文展示后仍自动前进。
  void _onSkipThinkingAnimation() {
    _typeTimer?.cancel();
    setState(() => _thinkingVisible = _thinkingFull.length);
    _scheduleAutoAdvanceAfterThinking();
  }

  Future<void> _pickLastAt() async {
    final root = _current;
    if (root == null) return;
    final isTime = root.parsedEventType == EventCatalogEventType.time;
    final title = isTime ? '上次结束时间' : '上次发生时间';
    final now = DateTime.now();
    final minDay = homeHistoryDateOnly(now.subtract(const Duration(days: 365)));
    final maxDay = homeHistoryDateOnly(now);
    final draft = _draftFor(root.id);

    // 单层玻璃 Sheet：默认时分，左上角切换日期。
    final picked = await showHomeHistoryDateTimeToggleSheet(
      context,
      minimumDate: minDay,
      maximumDate: maxDay,
      initialValue: draft.lastAt,
      title: title,
    );
    if (!mounted || picked == null) return;
    setState(() {
      draft.lastAt = picked;
      _showRecallHint = false;
    });
  }

  Future<void> _pickInterval() async {
    final items = <int>[
      for (var m = 15; m <= 24 * 60; m += 15) m,
    ];
    var idx = items.indexOf(_intervalMinutes);
    if (idx < 0) idx = items.indexOf(180).clamp(0, items.length - 1);
    final labels = [for (final m in items) _formatInterval(m)];
    final picked = await showGlassSingleWheelPickerSheet(
      context,
      title: '大概多久一次',
      labels: labels,
      initialIndex: idx,
    );
    if (!mounted || picked == null) return;
    final root = _current;
    if (root == null) return;
    setState(() {
      _draftFor(root.id).intervalMinutes = items[picked];
      _showRecallHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 浮层内文案跟 modal 前景原子
    final onShell = AppColor.textOnModal(context);
    final root = _current;
    final accent = (!_isFinalePage && root != null)
        ? resolveEventColor(context, root)
        : null;

    // 单一玻璃壳 + 底栏在 PageView 外：邻页不再叠禁用按钮吞点击。
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _FloatingCard(
        eventAccent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    // 禁止用户左右拖滑；仅确认 / 跳过 / 上一步程序切页
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pageCount,
                    onPageChanged: (i) {
                      setState(() {
                        _pageIndex = i;
                        _showRecallHint = false;
                        // 进入该页才确保草稿；已有则不覆盖。
                        _ensureCurrentDraft();
                      });
                    },
                    itemBuilder: (context, index) {
                      if (index >= _queue.length) {
                        return _buildFinaleScroll(onShell, scheme);
                      }
                      final pageRoot = _queue[index];
                      return _buildCardScroll(
                        onShell,
                        scheme,
                        root: pageRoot,
                        progress: '${index + 1}/${_queue.length}',
                        // 仅当前页展示真实选择值；邻页用占位避免错乱
                        interactive: index == _pageIndex,
                      );
                    },
                  ),
                  if (_showThinking && !_isFinalePage)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColor.modalFill(context),
                        child: _buildThinkingScroll(onShell, scheme),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_showThinking && !_isFinalePage)
              _buildThinkingFooter(onShell, scheme)
            else if (_isFinalePage)
              FilledButton(
                onPressed: widget.onFinished,
                child: const Text('体验胖宝智能预测'),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_pageIndex > 0)
                    TextButton(
                      onPressed: () => unawaited(_onBack()),
                      child: const Text('上一步'),
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showRecallHint) ...[
                        Text(
                          '请认真回忆事件',
                          style: TextStyle(
                            fontSize: 12,
                            // 语义错误色走 Theme ColorScheme，禁止 Colors.red / 手写 hex。
                            color: scheme.error,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      FilledButton(
                        onPressed: () => unawaited(_onConfirm()),
                        child: const Text('确认'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 卡片可滚内容（不含底栏按钮）。
  Widget _buildCardScroll(
    Color onShell,
    ColorScheme scheme, {
    required EventDefinition root,
    required String progress,
    required bool interactive,
  }) {
    final isTime = root.parsedEventType == EventCatalogEventType.time;
    final kids = _childEvents(root);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '智能预测推演 · $progress',
            style: TextStyle(
              fontSize: 13,
              color: onShell.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              EventLogo(definition: root, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  root.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: onShell,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: interactive ? () => unawaited(_onSkip()) : null,
                child: const Text('跳过'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isTime ? '还记得上次结束「${root.name}」是什么时候吗？' : '还记得上次发生「${root.name}」是什么时候吗？',
            style: TextStyle(
              fontSize: 15,
              color: onShell.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          _SelectTile(
            label: isTime ? '上次结束时间' : '上次发生时间',
            value: _timeFmt.format(interactive ? _lastAt : DateTime.now()),
            onTap: interactive ? () => unawaited(_pickLastAt()) : () {},
          ),
          const SizedBox(height: 10),
          _SelectTile(
            label: '大概多久一次',
            value: _formatInterval(interactive ? _intervalMinutes : 180),
            onTap: interactive ? () => unawaited(_pickInterval()) : () {},
          ),
          if (kids.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '该事件包含',
              style: TextStyle(
                fontSize: 13,
                color: onShell.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final kid in kids)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EventLogo(definition: kid, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        kid.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: onShell.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingScroll(Color onShell, ColorScheme scheme) {
    final text = _thinkingFull.substring(0, _thinkingVisible);
    return SingleChildScrollView(
      child: Column(
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
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.55,
              color: onShell.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingFooter(Color onShell, ColorScheme scheme) {
    final done = _thinkingVisible >= _thinkingFull.length;
    if (!done) {
      return FilledButton(
        onPressed: _onSkipThinkingAnimation,
        child: const Text('跳过动画'),
      );
    }
    return Text(
      '即将继续…',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: onShell.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildFinaleScroll(Color onShell, ColorScheme scheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child, this.eventAccent});

  final Widget child;
  final Color? eventAccent;

  @override
  Widget build(BuildContext context) {
    // 召回浮层外壳与登录/绑定引导同源 modal 原子；事件卡带色标
    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      color: Colors.transparent,
      child: AppModalGlassPanel(
        borderRadius: 24,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        eventAccent: eventAccent,
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
