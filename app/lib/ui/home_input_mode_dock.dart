import 'dart:async';

import 'package:flutter/material.dart';

import '../config/home_input_dock_store.dart';
import '../data/home_input_dock_geometry.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import 'home_input_channel.dart';

/// 贴边半露、可拖动吸附的输入模式切换器。
/// 贴边半圆：点击滑出整圆；贴边整圆 / 自由悬浮：点击切换模式。
class HomeInputModeDock extends StatefulWidget {
  const HomeInputModeDock({
    super.key,
    required this.bounds,
    required this.bottomInputPanelHeight,
    required this.currentChannel,
    required this.showButtonsOption,
    required this.onChannelSelected,
    this.restrictToHorizontalEdges = false,
  });

  final Rect bounds;
  final double bottomInputPanelHeight;
  final HomeInputChannel currentChannel;
  final bool showButtonsOption;
  final ValueChanged<HomeInputChannel> onChannelSelected;

  /// Web：仅左右吸附。
  final bool restrictToHorizontalEdges;

  @override
  State<HomeInputModeDock> createState() => _HomeInputModeDockState();
}

class _HomeInputModeDockState extends State<HomeInputModeDock> with TickerProviderStateMixin {
  static const _tapSlop = 12.0;
  static const _peakScale = 1.55;
  static const _popGrowFraction = 0.42;
  static const _revealDuration = Duration(milliseconds: 160);
  static const _popGrowDuration = Duration(milliseconds: 220);
  static const _popShrinkDuration = Duration(milliseconds: 300);
  static const _edgeHitExpand = 24.0;

  var _edge = kHomeInputDockDefaultEdge;
  var _along = kHomeInputDockDefaultAlong;
  Offset? _freeCenter;
  Offset? _dragCenter;
  var _isDragging = false;
  var _engaged = false;
  Offset? _pointerDownGlobal;
  var _cycleInProgress = false;
  /// pop 动画期间展示的图标（峰值前旧模式，峰值后新模式）。
  HomeInputChannel? _popDisplayChannel;

  late final AnimationController _revealController;
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: _revealDuration);
    _popController = AnimationController(vsync: this, duration: _popGrowDuration + _popShrinkDuration);
    unawaited(_loadDockPosition());
  }

  @override
  void didUpdateWidget(covariant HomeInputModeDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bounds == widget.bounds) return;
    setState(() {
      if (_freeCenter != null) {
        _freeCenter = clampDockCenterForDrag(_freeCenter!, widget.bounds);
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _popController.dispose();
    super.dispose();
  }

  Future<void> _loadDockPosition() async {
    final snap = await HomeInputDockStore.load();
    if (!mounted) return;
    setState(() {
      if (snap.isFloating) {
        _freeCenter = clampDockCenterForDrag(snap.freeCenter!, widget.bounds);
        _edge = kHomeInputDockDefaultEdge;
        _along = kHomeInputDockDefaultAlong;
        _engaged = false;
      } else {
        _freeCenter = null;
        _edge = snap.edge;
        _along = snap.along;
        _engaged = false;
      }
      _revealController.value = 0;
    });
  }

  bool get _isFloating => _freeCenter != null;

  /// 贴边且处于整圆（已滑出）状态。
  bool get _isEdgeFullCircle =>
      !_isFloating && (_engaged || _revealController.value >= 0.5);

  /// 贴边且处于半圆（未滑出）状态。
  bool get _isEdgeSemicircle => !_isFloating && !_isEdgeFullCircle;

  Offset get _snappedCenter => dockCircleCenterForSnapped(
        edge: _edge,
        along: _along,
        bounds: widget.bounds,
      );

  Offset _fullCenterForSnap() => dockCircleCenterForFullCircle(
        edge: _edge,
        along: _along,
        bounds: widget.bounds,
      );

  Offset _visualCenter({required double reveal}) {
    if (_dragCenter != null) return _dragCenter!;
    if (_freeCenter != null) return _freeCenter!;
    final semi = _snappedCenter;
    final full = _fullCenterForSnap();
    return Offset.lerp(semi, full, reveal.clamp(0.0, 1.0))!;
  }

  List<HomeInputChannel> get _availableChannels {
    if (widget.showButtonsOption) {
      return const [HomeInputChannel.buttons, HomeInputChannel.voice];
    }
    return const [HomeInputChannel.voice, HomeInputChannel.text];
  }

  HomeInputChannel _nextChannel(HomeInputChannel current) {
    final channels = _availableChannels;
    final index = channels.indexOf(current);
    if (index < 0) return channels.first;
    return channels[(index + 1) % channels.length];
  }

  Future<void> _persistSnap(DockEdge edge, double along) async {
    await HomeInputDockStore.saveEdge(edge, along);
  }

  Future<void> _persistFree(Offset center) async {
    await HomeInputDockStore.saveFree(center);
  }

  double _popScaleFor(double t) {
    if (t <= _popGrowFraction) {
      final growT = Curves.easeOut.transform(t / _popGrowFraction);
      return 1.0 + (_peakScale - 1.0) * growT;
    }
    final shrinkT = Curves.easeIn.transform((t - _popGrowFraction) / (1 - _popGrowFraction));
    return _peakScale - (_peakScale - 1.0) * shrinkT;
  }

  Future<void> _engage() async {
    if (_engaged || _cycleInProgress || _isFloating) return;
    setState(() => _engaged = true);
    await _revealController.forward();
  }

  Future<void> _disengage() async {
    if (!_engaged || _cycleInProgress || _isFloating) return;
    setState(() => _engaged = false);
    await _revealController.reverse();
  }

  Future<void> _cycleMode() async {
    if (_cycleInProgress) return;
    if (!_isFloating && !_isEdgeFullCircle) return;

    final next = _nextChannel(widget.currentChannel);
    _cycleInProgress = true;
    _popDisplayChannel = widget.currentChannel;
    _popController.value = 0;
    setState(() {});

    // 放大阶段：旧图标，避免底部面板立刻重排打断动画
    await _popController.animateTo(
      _popGrowFraction,
      duration: _popGrowDuration,
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    widget.onChannelSelected(next);
    setState(() => _popDisplayChannel = next);

    // 缩小阶段：新图标
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

  Offset _globalToBoundsLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_cycleInProgress) return;
    _pointerDownGlobal = event.position;
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerDownGlobal == null || _cycleInProgress) return;
    if (!_isDragging && (event.position - _pointerDownGlobal!).distance > _tapSlop) {
      _isDragging = true;
      setState(() {
        _dragCenter ??= _visualCenter(reveal: _revealController.value);
      });
    }
    if (!_isDragging) return;
    final local = _globalToBoundsLocal(event.position);
    setState(() => _dragCenter = clampDockCenterForDrag(local, widget.bounds));
  }

  Future<void> _finishDrag() async {
    final center = _dragCenter;
    if (center == null) return;
    final clamped = clampDockCenterForDrag(center, widget.bounds);
    final allowTopBottom = !widget.restrictToHorizontalEdges;
    if (dockShouldSnapToEdge(clamped, widget.bounds, allowTopBottom: allowTopBottom)) {
      final snap = snapDockToNearestEdge(
        clamped,
        widget.bounds,
        allowTopBottom: allowTopBottom,
      );
      setState(() {
        _freeCenter = null;
        _edge = snap.edge;
        _along = snap.along;
        _dragCenter = null;
        _engaged = false;
      });
      _revealController.value = 0;
      await _persistSnap(snap.edge, snap.along);
    } else {
      setState(() {
        _freeCenter = clamped;
        _dragCenter = null;
        _engaged = false;
      });
      _revealController.reset();
      await _persistFree(clamped);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_cycleInProgress) return;
    final wasDragging = _isDragging;
    _pointerDownGlobal = null;
    _isDragging = false;

    if (wasDragging) {
      unawaited(_finishDrag());
      return;
    }

    if (_isFloating) {
      unawaited(_cycleMode());
      return;
    }
    if (_isEdgeSemicircle) {
      unawaited(_engage());
    } else {
      unawaited(_cycleMode());
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownGlobal = null;
    _isDragging = false;
    if (_dragCenter != null) {
      setState(() => _dragCenter = null);
    }
  }

  ({double left, double top, double width, double height}) _hitTargetRect(Offset center) {
    if (_isFloating || _isEdgeFullCircle || _dragCenter != null) {
      const size = kHomeInputDockDiameter + _edgeHitExpand * 2;
      return (
        left: center.dx - size / 2,
        top: center.dy - size / 2,
        width: size,
        height: size,
      );
    }

    // 贴边半圆：向屏内扩大可点区域；视觉仍按圆心对齐边缘。
    const vertical = kHomeInputDockDiameter + 16.0;
    const inner = kHomeInputDockDiameter + _edgeHitExpand;
    return switch (_edge) {
      DockEdge.right => (
          left: center.dx - inner,
          top: center.dy - vertical / 2,
          width: inner,
          height: vertical,
        ),
      DockEdge.left => (
          left: center.dx,
          top: center.dy - vertical / 2,
          width: inner,
          height: vertical,
        ),
      DockEdge.top => (
          left: center.dx - vertical / 2,
          top: center.dy,
          width: vertical,
          height: inner,
        ),
      DockEdge.bottom => (
          left: center.dx - vertical / 2,
          top: center.dy - inner,
          width: vertical,
          height: inner,
        ),
    };
  }

  IconData _iconFor(HomeInputChannel channel) {
    return switch (channel) {
      HomeInputChannel.voice => Icons.mic_rounded,
      HomeInputChannel.text => Icons.keyboard_rounded,
      HomeInputChannel.buttons => Icons.grid_view_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _popController]),
      builder: (context, _) {
        final reveal = _revealController.value;
        final center = _visualCenter(reveal: reveal);
        final popT = _popController.value;
        final popActive = _cycleInProgress || popT > 0;
        final popScale = popActive ? _popScaleFor(popT.clamp(0.0, 1.0)) : 1.0;
        final displayChannel = _popDisplayChannel ?? widget.currentChannel;
        final hit = _hitTargetRect(center);
        final handleLeft = center.dx - kHomeInputDockRadius - hit.left;
        final handleTop = center.dy - kHomeInputDockRadius - hit.top;

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_isEdgeFullCircle)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: widget.bottomInputPanelHeight,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {},
                    onPointerUp: (_) => unawaited(_disengage()),
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned(
                left: hit.left,
                top: hit.top,
                width: hit.width,
                height: hit.height,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: handleLeft,
                        top: handleTop,
                        child: Transform.scale(
                          scale: popScale,
                          alignment: Alignment.center,
                          child: _buildDockHandle(context, displayChannel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDockHandle(BuildContext context, HomeInputChannel channel) {
    final handle = _buildHandle(context, channel);
    if (!_isEdgeSemicircle || _dragCenter != null) {
      return handle;
    }
    return SizedBox(
      width: kHomeInputDockDiameter,
      height: kHomeInputDockDiameter,
      child: ClipRect(
        child: Align(
          alignment: switch (_edge) {
            DockEdge.right => Alignment.centerLeft,
            DockEdge.left => Alignment.centerRight,
            DockEdge.top => Alignment.bottomCenter,
            DockEdge.bottom => Alignment.topCenter,
          },
          widthFactor: _edge == DockEdge.left || _edge == DockEdge.right ? 0.5 : 1.0,
          heightFactor: _edge == DockEdge.top || _edge == DockEdge.bottom ? 0.5 : 1.0,
          child: handle,
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context, HomeInputChannel channel) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final handleColor = tokens?.surfaceColor ?? themePrimaryBlend(context, alpha: 0.24);
    final handleShadow = tokens != null
        ? [
            BoxShadow(
              color: tokens.shellColor.withValues(alpha: tokens.isDarkShell ? 0.55 : 0.18),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: tokens.isDarkShell ? 0.28 : 0.12),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ]
        : null;

    final icon = Icon(
      _iconFor(channel),
      size: 22,
      color: scheme.primary,
    );

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
}
