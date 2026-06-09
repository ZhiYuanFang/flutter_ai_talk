import 'package:flutter/material.dart';

import '../../ui/home_screen.dart';
import 'ucg_enter_square_tab.dart';
import 'ucg_shell.dart';

class UcgHomeShell extends StatefulWidget {
  const UcgHomeShell({super.key});

  @override
  State<UcgHomeShell> createState() => _UcgHomeShellState();
}

class _UcgHomeShellState extends State<UcgHomeShell> {
  final _pageController = PageController();
  var _pageIndex = 0;
  var _blockPageScroll = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToUcg() async {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _pageController,
          physics: _blockPageScroll
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: (i) => setState(() => _pageIndex = i),
          children: [
            _KeepAliveHomeScreen(
              onDockDraggingChanged: (dragging) {
                if (_blockPageScroll != dragging) {
                  setState(() => _blockPageScroll = dragging);
                }
              },
            ),
            UcgShell(onBackToFeeding: _goToFeeding),
          ],
        ),
        if (_pageIndex == 0) UcgEnterSquareTab(onTap: _goToUcg),
      ],
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
