import 'dart:async';

import 'package:flutter/material.dart';

import '../config/home_input_dock_store.dart';
import '../data/edge_dock_occupancy.dart';
import '../data/home_input_dock_geometry.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import 'home_input_channel.dart';
import 'widgets/edge_dock_shell.dart';

/// 贴边半露、可拖动吸附的输入模式切换器（EdgeDockShell 消费者）。
/// 贴边半圆：点击/拉入滑出整圆；贴边整圆 / 自由悬浮：点击切换模式。
class HomeInputModeDock extends StatefulWidget {
  const HomeInputModeDock({
    super.key,
    required this.bounds,
    required this.bottomInputPanelHeight,
    required this.currentChannel,
    required this.dockCycleChannels,
    required this.onChannelSelected,
    this.restrictToHorizontalEdges = false,
    this.onDraggingChanged,
  });

  final Rect bounds;
  final double bottomInputPanelHeight;
  final HomeInputChannel currentChannel;
  final List<HomeInputChannel> dockCycleChannels;
  final ValueChanged<HomeInputChannel> onChannelSelected;
  final bool restrictToHorizontalEdges;
  final ValueChanged<bool>? onDraggingChanged;

  @override
  State<HomeInputModeDock> createState() => _HomeInputModeDockState();
}

class _HomeInputModeDockState extends State<HomeInputModeDock>
    with SingleTickerProviderStateMixin {
  static const _peakScale = 1.55;
  static const _popGrowFraction = 0.42;
  static const _popGrowDuration = Duration(milliseconds: 220);
  static const _popShrinkDuration = Duration(milliseconds: 300);

  final _dockController = EdgeDockController();
  EdgeDockPlacement? _placement;
  var _cycleInProgress = false;
  HomeInputChannel? _popDisplayChannel;
  late final AnimationController _popController;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: _popGrowDuration + _popShrinkDuration,
    );
    unawaited(_loadDockPosition());
  }

  @override
  void dispose() {
    _popController.dispose();
    _dockController.dispose();
    super.dispose();
  }

  Future<void> _loadDockPosition() async {
    final snap = await HomeInputDockStore.load();
    if (!mounted) return;
    setState(() {
      if (snap.isFloating) {
        _placement = EdgeDockPlacement.floating(freeCenter: snap.freeCenter!);
      } else {
        _placement = EdgeDockPlacement.edge(
          kind: EdgeDockKind.edgePeek,
          edge: snap.edge,
          along: snap.along,
        );
      }
      _loaded = true;
    });
    // 壳 init 后强制同步
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _placement == null) return;
      final p = _placement!;
      if (p.isFloating && p.freeCenter != null) {
        _dockController.showFloating(p.freeCenter!);
      } else {
        _dockController.showPeek(p.edge, p.along);
      }
    });
  }

  List<HomeInputChannel> get _availableChannels => widget.dockCycleChannels;

  HomeInputChannel _nextChannel(HomeInputChannel current) {
    final channels = _availableChannels;
    final index = channels.indexOf(current);
    if (index < 0) return channels.first;
    return channels[(index + 1) % channels.length];
  }

  Future<void> _onPlacementChanged(EdgeDockPlacement p) async {
    _placement = p;
    if (p.isFloating && p.freeCenter != null) {
      await HomeInputDockStore.saveFree(p.freeCenter!);
    } else {
      await HomeInputDockStore.saveEdge(p.edge, p.along);
    }
  }

  double _popScaleFor(double t) {
    if (t <= _popGrowFraction) {
      final growT = Curves.easeOut.transform(t / _popGrowFraction);
      return 1.0 + (_peakScale - 1.0) * growT;
    }
    final shrinkT =
        Curves.easeIn.transform((t - _popGrowFraction) / (1 - _popGrowFraction));
    return _peakScale - (_peakScale - 1.0) * shrinkT;
  }

  Future<void> _cycleMode() async {
    if (_cycleInProgress) return;
    final next = _nextChannel(widget.currentChannel);
    _cycleInProgress = true;
    _popDisplayChannel = widget.currentChannel;
    _popController.value = 0;
    setState(() {});

    await _popController.animateTo(
      _popGrowFraction,
      duration: _popGrowDuration,
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    widget.onChannelSelected(next);
    setState(() => _popDisplayChannel = next);

    await _popController.animateTo(
      1.0,
      duration: _popShrinkDuration,
      curve: Curves.easeIn,
    );
    if (!mounted) return;

    _popController.value = 0;
    _popDisplayChannel = null;
    setState(() => _cycleInProgress = false);
  }

  IconData _iconFor(HomeInputChannel channel) {
    return switch (channel) {
      HomeInputChannel.voice => Icons.mic_rounded,
      HomeInputChannel.text => Icons.keyboard_rounded,
      HomeInputChannel.buttons => Icons.grid_view_rounded,
    };
  }

  Widget _buildHandle(BuildContext context, HomeInputChannel channel) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final handleColor =
        tokens?.surfaceColor ?? themePrimaryBlend(context, alpha: 0.24);
    final handleShadow = tokens != null
        ? [
            BoxShadow(
              color: tokens.shellColor
                  .withValues(alpha: tokens.isDarkShell ? 0.55 : 0.18),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: scheme.primary
                  .withValues(alpha: tokens.isDarkShell ? 0.28 : 0.12),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ]
        : null;

    final icon = Icon(_iconFor(channel), size: 22, color: scheme.primary);

    if (tokens != null) {
      return Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: handleColor,
            border: Border.all(color: tokens.surfaceBorderColor),
            boxShadow: handleShadow,
          ),
          child: SizedBox(
            width: kHomeInputDockDiameter,
            height: kHomeInputDockDiameter,
            child: Center(child: icon),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      shadowColor: scheme.primary.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      color: handleColor,
      child: SizedBox(
        width: kHomeInputDockDiameter,
        height: kHomeInputDockDiameter,
        child: Center(child: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _placement == null) {
      return const SizedBox.expand();
    }

    return AnimatedBuilder(
      animation: _popController,
      builder: (context, _) {
        final popT = _popController.value;
        final popActive = _cycleInProgress || popT > 0;
        final popScale = popActive ? _popScaleFor(popT.clamp(0.0, 1.0)) : 1.0;
        final displayChannel = _popDisplayChannel ?? widget.currentChannel;

        return EdgeDockShell(
          bounds: widget.bounds,
          controller: _dockController,
          initialPlacement: _placement!,
          allowTopBottom: !widget.restrictToHorizontalEdges,
          bottomScrimInset: widget.bottomInputPanelHeight,
          showEngagedScrim: true,
          occupancyId: kEdgeDockOccupancyModeId,
          occupancySticky: true,
          onPointerOccupied: widget.onDraggingChanged,
          onPlacementChanged: (p) => unawaited(_onPlacementChanged(p)),
          onInteractiveTap: () => unawaited(_cycleMode()),
          child: Transform.scale(
            scale: popScale,
            alignment: Alignment.center,
            child: _buildHandle(context, displayChannel),
          ),
        );
      },
    );
  }
}
