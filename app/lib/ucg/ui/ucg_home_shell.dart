import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/app_debug_log.dart';
import '../../bootstrap/gateway_bootstrap_gate.dart';
import '../../bootstrap/history_ws_home_bridge.dart';
import '../../bootstrap/pangbao_transport_release.dart';
import '../../data/models.dart';
import '../../home_widget/home_widget_sync.dart';
import '../../providers/device_no_notifier.dart';
import '../../providers/home_pager.dart';
import '../../providers/history_event_fly_provider.dart';
import '../../providers/prediction_care_alert_provider.dart';
import '../../providers/prediction_range_history_provider.dart';
import '../../providers/prediction_recall_provider.dart';
import '../../providers/repositories.dart';
import '../../providers/session_provider.dart';
import '../../providers/toast_bus.dart';
import '../../ui/history_event_fly_overlay.dart';
import '../../ui/home_screen.dart';
import '../../ui/prediction_card_fly_landing.dart';
import '../../ui/smart_prediction_screen.dart';
import '../data/ucg_feature_flags.dart';
import 'ucg_shell.dart';

class UcgHomeShell extends ConsumerStatefulWidget {
  const UcgHomeShell({super.key});

  @override
  ConsumerState<UcgHomeShell> createState() => _UcgHomeShellState();
}

class _UcgHomeShellState extends ConsumerState<UcgHomeShell> {
  static const _exitConfirmWindow = Duration(seconds: 3);
  static const _iosHistoryWsConnectDelay = Duration(seconds: 2);

  // 默认着陆智能预测主页（中间页）
  late final PageController _pageController =
      PageController(initialPage: HomePagerPage.prediction);
  var _pageIndex = HomePagerPage.prediction;
  // 预测为默认着陆：冷启动即挂载
  var _predictionEverMounted = true;
  var _ucgEverMounted = false;
  var _blockPageScroll = false;
  DateTime? _lastExitBackPress;

  /// 主壳历史 WS 单一订阅（喂养页不得再挂）
  StreamSubscription<SseHistoryPayload>? _historyWsSub;
  var _historyWsActivateInFlight = false;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    // 主壳会话门闸：允许 history reconnect / UCG desired
    PangbaoHomeTransportGate.onHomeMounted();
    // 首帧即触发预测页 CareAlert ensure（可见即拉）；同步飞入门闸页索引
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homePagerIndexProvider.notifier).state = _pageIndex;
      _ensureCareAlertOnPredictionVisible();
      unawaited(_activateHistoryWsSessionIfNeeded());
    });
  }

  @override
  void dispose() {
    _historyWsSub?.cancel();
    _historyWsSub = null;
    PangbaoHomeTransportGate.onHomeUnmounted();
    // 离开主壳：释放同 host 传输（登出路径也会 release，幂等）
    try {
      unawaited(releasePangbaoHomeTransports(ref));
    } catch (_) {}
    _pageController.dispose();
    super.dispose();
  }

  /// gateway 后订阅 + ensure；游客跳过；single-flight。
  Future<void> _activateHistoryWsSessionIfNeeded() async {
    if (_historyWsActivateInFlight) return;
    if (!ref.read(sessionProvider).isLoggedIn) return;
    _historyWsActivateInFlight = true;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await GatewayBootstrapGate.ensureLoggedInComplete(container);
      if (!mounted || !ref.read(sessionProvider).isLoggedIn) return;
      // iOS：错开同 host 连接槽
      if (!kIsWeb && Platform.isIOS) {
        await Future<void>.delayed(_iosHistoryWsConnectDelay);
        if (!mounted || !ref.read(sessionProvider).isLoggedIn) return;
      }
      final feed = ref.read(feedRepositoryProvider);
      _historyWsSub ??= feed.watchLatest().listen(
            (payload) => applyHistoryWsPayloadToHome(ref, payload),
          );
      feed.ensureHistoryWebSocketConnected();
    } finally {
      _historyWsActivateInFlight = false;
    }
  }

  void _onHistorySessionLoggedOut() {
    _historyWsSub?.cancel();
    _historyWsSub = null;
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
    // UCG 暂停时不会出现 index==ucg；保留分支便于翻回闸门
    if (kUcgHomePagerEnabled && index == HomePagerPage.ucg) {
      _markUcgMounted();
    }
    setState(() => _pageIndex = index);
    ref.read(homePagerIndexProvider.notifier).state = index;
  }

  Future<void> _goToPage(int page) async {
    // UCG 暂停：落到预测，避免空白页
    final target = (!kUcgHomePagerEnabled && page == HomePagerPage.ucg)
        ? HomePagerPage.prediction
        : page;
    // 预测页重抽/ensure 由 onPageChanged 统一处理；已在预测页时仅补 ensure
    if (target == HomePagerPage.prediction &&
        _pageIndex == HomePagerPage.prediction) {
      _ensureCareAlertOnPredictionVisible();
    }
    if (kUcgHomePagerEnabled && target == HomePagerPage.ucg) {
      _markUcgMounted();
    }
    if (target == HomePagerPage.prediction) _markPredictionMounted();
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (mounted) {
      setState(() => _pageIndex = target);
      ref.read(homePagerIndexProvider.notifier).state = target;
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
        (kUcgHomePagerEnabled && _pageIndex == HomePagerPage.ucg)) {
      // 喂养（及开启时的广场）：先回预测主页
      unawaited(_goToHomeHub());
    } else if (_pageIndex == HomePagerPage.prediction) {
      _onPredictionExitBackPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigatorCanPop = Navigator.of(context).canPop();

    // 游客→登录：主壳补激活历史 WS；登出清订阅（disconnect 由 release 负责）
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn),
        (prev, loggedIn) {
      if (prev == true && !loggedIn) {
        _onHistorySessionLoggedOut();
        return;
      }
      if (prev == true || !loggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_activateHistoryWsSessionIfNeeded());
      });
    });

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
          // UCG 页：仅闸门开启且 itemCount=3 时可达
          if (!kUcgHomePagerEnabled) {
            return const SizedBox.expand();
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
      if (MediaQuery.disableAnimationsOf(context)) {
        ref
            .read(historyEventFlyRequestProvider.notifier)
            .clearIfSession(next.session);
        return;
      }
      // 等预测行按 nextAt 重排并完成至少 2 帧布局后再挂 Overlay 测锚。
      final session = next.session;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final latest = ref.read(historyEventFlyRequestProvider);
          if (latest == null || latest.session != session) return;
          if (MediaQuery.disableAnimationsOf(context)) {
            ref
                .read(historyEventFlyRequestProvider.notifier)
                .clearIfSession(session);
            return;
          }
          setState(() => _flyReq = latest);
        });
      });
    });

    final req = _flyReq;
    final registry = ref.watch(predictionLogoAnchorRegistryProvider);
    final rootId = req?.rootEventId.trim() ?? '';
    // keyFor：确保有 GlobalKey，离屏卡可 ensureVisible 后再测锚
    final logoKey = rootId.isEmpty ? null : registry.keyFor(rootId);
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
                  logoAnchorKey: logoKey,
                ),
                onComplete: () => _onFlyComplete(req.session),
              ),
            ),
          ),
      ],
    );
  }
}
