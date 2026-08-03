import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/clinic_ws_provider.dart';
import '../../providers/home_pager.dart';
import '../../providers/toast_bus.dart';
import '../../ui/home_screen.dart';
import '../../ui/pangbao_ai_screen.dart';
import 'ucg_shell.dart';

class UcgHomeShell extends ConsumerStatefulWidget {
  const UcgHomeShell({super.key});

  @override
  ConsumerState<UcgHomeShell> createState() => _UcgHomeShellState();
}

class _UcgHomeShellState extends ConsumerState<UcgHomeShell> {
  static const _exitConfirmWindow = Duration(seconds: 3);

  // 默认着陆喂养页（中间页）
  late final PageController _pageController =
      PageController(initialPage: HomePagerPage.feeding);
  var _pageIndex = HomePagerPage.feeding;
  var _companionEverMounted = false;
  var _ucgEverMounted = false;
  var _blockPageScroll = false;
  DateTime? _lastExitBackPress;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markCompanionMounted() {
    if (_companionEverMounted) return;
    setState(() => _companionEverMounted = true);
    // 首次挂载后尝试激活 Clinic WS（同意/登录/绑宝门闩在 activate 内）
    unawaited(activateCompanionClinicWs(ref));
  }

  void _markUcgMounted() {
    if (_ucgEverMounted) return;
    setState(() => _ucgEverMounted = true);
  }

  void _notifyCompanionEnter() {
    // 通知 KeepAlive 陪伴页执行 tip / 问候门闩
    ref.read(companionEnterSignalProvider.notifier).state++;
  }

  void _onPageChanged(int index) {
    if (index == HomePagerPage.companion) {
      _markCompanionMounted();
      unawaited(ensureCompanionClinicWsConnected(ref));
      _notifyCompanionEnter();
    }
    if (index == HomePagerPage.ucg) _markUcgMounted();
    setState(() => _pageIndex = index);
  }

  Future<void> _goToPage(int page) async {
    if (page == HomePagerPage.companion) _markCompanionMounted();
    if (page == HomePagerPage.ucg) _markUcgMounted();
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _pageIndex = page);
    // companion 进入通知统一走 onPageChanged，避免与 animate 完成重复触发
  }

  Future<void> _goToFeeding() => _goToPage(HomePagerPage.feeding);

  void _onFeedingExitBackPress() {
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
    if (_pageIndex == HomePagerPage.companion || _pageIndex == HomePagerPage.ucg) {
      // 陪伴/广场：先回喂养
      unawaited(_goToFeeding());
    } else if (_pageIndex == HomePagerPage.feeding) {
      _onFeedingExitBackPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigatorCanPop = Navigator.of(context).canPop();

    // tip / 深链等请求切页
    ref.listen<int?>(homePagerRequestProvider, (prev, next) {
      if (next == null) return;
      unawaited(_goToPage(next).whenComplete(() {
        if (mounted) ref.read(homePagerRequestProvider.notifier).clear();
      }));
    });

    // 陪伴按住说话时禁横滑（与 dock 拖动禁滑叠加）
    final voiceHoldBlocksScroll = ref.watch(homePagerScrollBlockedProvider);

    return PopScope(
      canPop: navigatorCanPop || !_isAndroid,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onRootBackInvoked();
      },
      // 喂养页无贴边拉条；侧页靠横滑 / tip「对话」/ pager 进入
      child: PageView.builder(
        controller: _pageController,
        itemCount: HomePagerPage.count,
        // 静止可滑；仅 dock/tip 拖动或陪伴按住时禁滑
        physics: (_blockPageScroll || voiceHoldBlocksScroll)
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (index == HomePagerPage.companion) {
            // 懒挂载：未进入过则占位
            if (!_companionEverMounted) {
              return const SizedBox.expand();
            }
            return const _KeepAliveCompanionPage();
          }
          if (index == HomePagerPage.feeding) {
            return _KeepAliveHomeScreen(
              onDockDraggingChanged: (dragging) {
                if (_blockPageScroll != dragging) {
                  setState(() => _blockPageScroll = dragging);
                }
              },
            );
          }
          if (!_ucgEverMounted) {
            return const SizedBox.expand();
          }
          return UcgShell(onBackToFeeding: _goToFeeding);
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

/// 陪伴页 KeepAlive：滑走不销毁 State，便于 WS 订阅与会话内存保持。
class _KeepAliveCompanionPage extends StatefulWidget {
  const _KeepAliveCompanionPage();

  @override
  State<_KeepAliveCompanionPage> createState() => _KeepAliveCompanionPageState();
}

class _KeepAliveCompanionPageState extends State<_KeepAliveCompanionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // embedded：嵌入主页 pager，不自管路由 pop / 不 dispose 壳级 WS
    return const PangbaoAiScreen(embeddedInHomePager: true);
  }
}
