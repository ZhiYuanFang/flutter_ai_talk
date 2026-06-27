import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/toast_bus.dart';
import '../../ui/home_screen.dart';
import 'ucg_enter_square_tab.dart';
import 'ucg_shell.dart';

class UcgHomeShell extends ConsumerStatefulWidget {
  const UcgHomeShell({super.key});

  @override
  ConsumerState<UcgHomeShell> createState() => _UcgHomeShellState();
}

class _UcgHomeShellState extends ConsumerState<UcgHomeShell> {
  static const _exitConfirmWindow = Duration(seconds: 3);

  final _pageController = PageController();
  var _pageIndex = 0;
  var _ucgEverMounted = false;
  var _blockPageScroll = false;
  DateTime? _lastExitBackPress;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markUcgMounted() {
    if (_ucgEverMounted) return;
    setState(() => _ucgEverMounted = true);
  }

  void _onPageChanged(int index) {
    if (index == 1) _markUcgMounted();
    setState(() => _pageIndex = index);
  }

  Future<void> _goToUcg() async {
    _markUcgMounted();
    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _pageIndex = 1);
  }

  Future<void> _goToFeeding() async {
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _pageIndex = 0);
  }

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
    if (_pageIndex == 1) {
      unawaited(_goToFeeding());
    } else if (_pageIndex == 0) {
      _onFeedingExitBackPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigatorCanPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: navigatorCanPop || !_isAndroid,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onRootBackInvoked();
      },
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: 2,
            physics: _blockPageScroll
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              if (index == 0) {
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
          if (_pageIndex == 0) UcgEnterSquareTab(onTap: _goToUcg),
        ],
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

class _KeepAliveHomeScreenState extends State<_KeepAliveHomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return HomeScreen(onDockDraggingChanged: widget.onDockDraggingChanged);
  }
}
