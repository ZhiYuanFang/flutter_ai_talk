import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/app_debug_log.dart';
import '../../home_widget/home_widget_sync.dart';
import '../../providers/device_no_notifier.dart';
import '../../providers/home_pager.dart';
import '../../providers/history_event_fly_provider.dart';
import '../../providers/prediction_care_alert_provider.dart';
import '../../providers/prediction_range_history_provider.dart';
import '../../providers/prediction_recall_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/toast_bus.dart';
import '../../ui/history_event_fly_overlay.dart';
import '../../ui/home_screen.dart';
import '../../ui/prediction_card_fly_landing.dart';
import '../../ui/smart_prediction_screen.dart';
import 'ucg_shell.dart';

class UcgHomeShell extends ConsumerStatefulWidget {
  const UcgHomeShell({super.key});

  @override
  ConsumerState<UcgHomeShell> createState() => _UcgHomeShellState();
}

class _UcgHomeShellState extends ConsumerState<UcgHomeShell> {
  static const _exitConfirmWindow = Duration(seconds: 3);

  // 默认着陆智能预测主页（中间页）
  late final PageController _pageController =
      PageController(initialPage: HomePagerPage.prediction);
  var _pageIndex = HomePagerPage.prediction;
  // 预测为默认着陆：冷启动即挂载
  var _predictionEverMounted = true;
  var _ucgEverMounted = false;
  var _blockPageScroll = false;
  DateTime? _lastExitBackPress;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    // 首帧即触发预测页 CareAlert ensure（可见即拉）；同步飞入门闸页索引
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homePagerIndexProvider.notifier).state = _pageIndex;
      _ensureCareAlertOnPredictionVisible();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markPredictionMounted() {
    if (_predictionEverMounted) return;
    setState(() => _predictionEverMounted = true);
  }

  void _markUcgMounted() {
    if (_ucgEverMounted) return;
    setState(() => _ucgEverMounted = true);
  }

  /// 进入预测页：仅真历史非空时日拉取（冷态禁止副作用 HTTP）。
  void _ensureCareAlertOnPredictionVisible() {
    final allowed = ref.read(predictionCareAlertFetchAllowedProvider);
    if (!allowed) {
      final loggedIn = ref.read(sessionProvider).isLoggedIn;
      final dn =
          ref.read(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
      final range = ref.read(predictionRangeHistoryProvider);
      AppDebugLog.careAlert(
        'ensure skipped gate loggedIn=$loggedIn dnLen=${dn.length} '
        'rangeReady=${range.ready} rangeLoading=${range.loading} '
        'itemCount=${range.items.length}',
      );
      return;
    }
    ref.invalidate(predictionCareAlertEnsureProvider);
    unawaited(() async {
      await ref.read(predictionCareAlertStateProvider.notifier).ensureLoaded();
      // 留意就绪后推桌面 tip（复用列表，不另发 tip HTTP）
      if (!mounted) return;
      await scheduleHomeWidgetSync(ref);
    }());
  }

  /// 进入预测页：重抽骨架偏移，并按门闸 ensure 留意。
  void _onEnterPredictionPage() {
    _markPredictionMounted();
    final now = DateTime.now();
    ref.read(predictionDemoMountNowProvider.notifier).state = now;
    ref.read(predictionDemoMountNonceProvider.notifier).state =
        now.microsecondsSinceEpoch;
    _ensureCareAlertOnPredictionVisible();
  }

  void _onPageChanged(int index) {
    if (index == HomePagerPage.prediction) {
      _onEnterPredictionPage();
    }
    if (index == HomePagerPage.ucg) _markUcgMounted();
    setState(() => _pageIndex = index);
    ref.read(homePagerIndexProvider.notifier).state = index;
  }

  Future<void> _goToPage(int page) async {
    // 预测页重抽/ensure 由 onPageChanged 统一处理；已在预测页时仅补 ensure
    if (page == HomePagerPage.prediction &&
        _pageIndex == HomePagerPage.prediction) {
      _ensureCareAlertOnPredictionVisible();
    }
    if (page == HomePagerPage.ucg) _markUcgMounted();
    if (page == HomePagerPage.prediction) _markPredictionMounted();
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (mounted) {
      setState(() => _pageIndex = page);
      ref.read(homePagerIndexProvider.notifier).state = page;
    }
  }

  /// UCG / 侧页「回主页」：回到智能预测。
  Future<void> _goToHomeHub() => _goToPage(HomePagerPage.prediction);

  void _onPredictionExitBackPress() {
    final now = DateTime.now();
    final last = _lastExitBackPress;
    if (last != null && now.difference(last) <= _exitConfirmWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastExitBackPress = now;
    ref.showApiToast('再试一次退出胖宝');
  }

  void _onRootBackInvoked() {
    if (!_isAndroid) return;
    if (_pageIndex == HomePagerPage.feeding ||
        _pageIndex == HomePagerPage.ucg) {
      // 喂养/广场：先回预测主页
      unawaited(_goToHomeHub());
    } else if (_pageIndex == HomePagerPage.prediction) {
      _onPredictionExitBackPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigatorCanPop = Navigator.of(context).canPop();

    // 贴士 / 深链等请求切页
    ref.listen<int?>(homePagerRequestProvider, (prev, next) {
      if (next == null) return;
      unawaited(_goToPage(next).whenComplete(() {
        if (mounted) ref.read(homePagerRequestProvider.notifier).clear();
      }));
    });

    // 门闸 false→true：稳定补 ensure（覆盖首帧 range 未就绪竞态）
    ref.listen<bool>(predictionCareAlertFetchAllowedProvider, (prev, next) {
      if (_pageIndex != HomePagerPage.prediction) return;
      if (prev == true || next != true) return;
      _ensureCareAlertOnPredictionVisible();
    });

    // 真历史从空变为非空：冗余补拉（与 fetchAllowed 边沿重叠时 single-flight）
    ref.listen(predictionRangeHistoryProvider, (prev, next) {
      if (_pageIndex != HomePagerPage.prediction) return;
      if (!next.ready || next.loading || next.items.isEmpty) return;
      final wasEmpty = prev == null || !prev.ready || prev.items.isEmpty;
      if (wasEmpty) _ensureCareAlertOnPredictionVisible();
    });

    final voiceHoldBlocksScroll = ref.watch(homePagerScrollBlockedProvider);

    return PopScope(
      canPop: navigatorCanPop || !_isAndroid,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onRootBackInvoked();
      },
      child: PageView.builder(
        controller: _pageController,
        itemCount: HomePagerPage.count,
        physics: (_blockPageScroll || voiceHoldBlocksScroll)
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (index == HomePagerPage.feeding) {
            return _KeepAliveHomeScreen(
              onDockDraggingChanged: (dragging) {
                if (_blockPageScroll != dragging) {
                  setState(() => _blockPageScroll = dragging);
                }
              },
            );
          }
          if (index == HomePagerPage.prediction) {
            if (!_predictionEverMounted) {
              return const SizedBox.expand();
            }
            return const _KeepAlivePredictionPage();
          }
          if (!_ucgEverMounted) {
            return const SizedBox.expand();
          }
          // 回调名保留；行为回预测主页
          return UcgShell(onBackToFeeding: _goToHomeHub);
        },
      ),
    );
  }
}

class _KeepAliveHomeScreen extends StatefulWidget {
  const _KeepAliveHomeScreen({this.onDockDraggingChanged});

  final ValueChanged<bool>? onDockDraggingChanged;

  @override
  State<_KeepAliveHomeScreen> createState() => _KeepAliveHomeScreenState();
}

class _KeepAliveHomeScreenState extends State<_KeepAliveHomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return HomeScreen(onDockDraggingChanged: widget.onDockDraggingChanged);
  }
}

/// 智能预测页 KeepAlive：滑走不销毁 State；承接可见页落库飞入。
class _KeepAlivePredictionPage extends ConsumerStatefulWidget {
  const _KeepAlivePredictionPage();

  @override
  ConsumerState<_KeepAlivePredictionPage> createState() =>
      _KeepAlivePredictionPageState();
}

class _KeepAlivePredictionPageState
    extends ConsumerState<_KeepAlivePredictionPage>
    with AutomaticKeepAliveClientMixin {
  HistoryEventFlyRequest? _flyReq;

  @override
  bool get wantKeepAlive => true;

  void _onFlyComplete(int session) {
    if (!mounted) return;
    ref.read(historyEventFlyRequestProvider.notifier).clearIfSession(session);
    if (_flyReq?.session == session) {
      setState(() => _flyReq = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<HistoryEventFlyRequest?>(historyEventFlyRequestProvider,
        (prev, next) {
      if (next == null) return;
      if (next.targetPage != HomePagerPage.prediction) return;
      if (prev?.session == next.session) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      setState(() => _flyReq = next);
    });

    final req = _flyReq;
    final registry = ref.watch(predictionLogoAnchorRegistryProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        const SmartPredictionScreen(),
        if (req != null)
          Positioned.fill(
            child: RepaintBoundary(
              child: HistoryEventFlyOverlay(
                key: ValueKey<int>(req.session),
                event: req.event,
                landing: PredictionCardFlyLanding(
                  logoAnchorKey: registry.maybeKey(req.rootEventId),
                ),
                onComplete: () => _onFlyComplete(req.session),
              ),
            ),
          ),
      ],
    );
  }
}
