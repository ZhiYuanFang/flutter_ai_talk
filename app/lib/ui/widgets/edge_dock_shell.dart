import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/edge_dock_geometry.dart';
import '../../data/edge_dock_occupancy.dart';
import '../../data/edge_dock_placement.dart';

export '../../data/edge_dock_placement.dart';

/// 通用贴边球壳：peek / engaged / floating、热区、锁滑、累计向内拉。
///
/// 业务（模式切换、tip 文案）由宿主通过 [child] 与回调提供。
class EdgeDockShell extends StatefulWidget {
  const EdgeDockShell({
    super.key,
    required this.bounds,
    required this.child,
    this.diameter = kDefaultEdgeDockDiameter,
    this.hitExpand = kDefaultEdgeDockHitExpand,
    this.allowTopBottom = true,
    this.bottomScrimInset = 0,
    this.showEngagedScrim = true,
    this.initialPlacement = const EdgeDockPlacement.edge(
      kind: EdgeDockKind.edgePeek,
      edge: DockEdge.right,
      along: 0.75,
    ),
    this.controller,
    this.onPointerOccupied,
    this.onPlacementChanged,
    /// floating / engaged 点按（peek 点按永不走此回调）
    this.onInteractiveTap,
    /// peek 累计拉满阈值后：先 engage，再可选触发宿主业务（点按永不走此回调）
    this.onPullBusiness,
    this.pullInThreshold = 28,
    /// 非空则接入共享占位表（松手/强制放置解冲突）
    this.occupancyId,
    this.occupancySticky = false,
    this.occupancy,
  });

  final Rect bounds;
  final Widget child;
  final double diameter;
  final double hitExpand;
  final bool allowTopBottom;
  final double bottomScrimInset;
  final bool showEngagedScrim;
  final EdgeDockPlacement initialPlacement;
  final EdgeDockController? controller;
  final ValueChanged<bool>? onPointerOccupied;
  final ValueChanged<EdgeDockPlacement>? onPlacementChanged;
  final VoidCallback? onInteractiveTap;
  final VoidCallback? onPullBusiness;
  final double pullInThreshold;
  final String? occupancyId;
  final bool occupancySticky;
  final EdgeDockOccupancy? occupancy;

  @override
  State<EdgeDockShell> createState() => _EdgeDockShellState();
}

/// 宿主强制切换放置（如 tip 过半吸附）。
class EdgeDockController extends ChangeNotifier {
  _EdgeDockShellState? _client;

  void _attach(_EdgeDockShellState s) => _client = s;
  void _detach(_EdgeDockShellState s) {
    if (_client == s) _client = null;
  }

  void showPeek(DockEdge edge, double along) {
    _client?._applyPeek(edge, along);
  }

  void showFloating(Offset center) {
    _client?._applyFloating(center);
  }
}

class _EdgeDockShellState extends State<EdgeDockShell>
    with SingleTickerProviderStateMixin {
  static const _tapSlop = 12.0;
  static const _revealDuration = Duration(milliseconds: 160);

  // 非 late：浮空初始路径也必须可读（热区计算用 edge）
  DockEdge _edge = DockEdge.right;
  double _along = 0.5;
  Offset? _freeCenter;
  var _engaged = false;
  Offset? _dragCenter;
  var _isDragging = false;
  Offset? _pointerDownGlobal;
  var _inwardAccum = 0.0;
  var _pageScrollLocked = false;

  late final AnimationController _revealController;

  double get _radius => widget.diameter / 2;

  bool get _isFloating => _freeCenter != null;

  bool get _isEdgeFullCircle =>
      !_isFloating && (_engaged || _revealController.value >= 0.5);

  bool get _isEdgeSemicircle => !_isFloating && !_isEdgeFullCircle;

  EdgeDockOccupancy get _occupancy =>
      widget.occupancy ?? EdgeDockOccupancy.instance;

  @override
  void initState() {
    super.initState();
    _revealController =
        AnimationController(vsync: this, duration: _revealDuration);
    final initial = _resolveIfNeeded(widget.initialPlacement);
    _applyInitial(initial);
    _syncOccupancy();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant EdgeDockShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.bounds != widget.bounds && _freeCenter != null) {
      _freeCenter = clampDockCenterForDrag(
        _freeCenter!,
        widget.bounds,
        diameter: widget.diameter,
      );
    }
  }

  @override
  void dispose() {
    final id = widget.occupancyId;
    if (id != null) _occupancy.unregister(id);
    widget.controller?._detach(this);
    _revealController.dispose();
    super.dispose();
  }

  EdgeDockPlacement _resolveIfNeeded(EdgeDockPlacement desired) {
    final id = widget.occupancyId;
    if (id == null) return desired;
    return _occupancy.resolve(
      id: id,
      desired: desired,
      bounds: widget.bounds,
      allowTopBottom: widget.allowTopBottom,
      diameter: widget.diameter,
    );
  }

  void _syncOccupancy() {
    final id = widget.occupancyId;
    if (id == null) return;
    _occupancy.register(
      id,
      placement: _placement,
      sticky: widget.occupancySticky,
      diameter: widget.diameter,
    );
  }

  void _applyInitial(EdgeDockPlacement p) {
    // 浮空也写入 edge/along，避免 build 读 late 未初始化
    _edge = p.edge;
    _along = p.along;
    if (p.isFloating && p.freeCenter != null) {
      _freeCenter = clampDockCenterForDrag(
        p.freeCenter!,
        widget.bounds,
        diameter: widget.diameter,
      );
      _engaged = false;
      _revealController.value = 0;
    } else {
      _freeCenter = null;
      _engaged = p.isEngaged;
      _revealController.value = p.isEngaged ? 1 : 0;
    }
  }

  void _setPlacementState(EdgeDockPlacement p) {
    if (p.isFloating && p.freeCenter != null) {
      _freeCenter = clampDockCenterForDrag(
        p.freeCenter!,
        widget.bounds,
        diameter: widget.diameter,
      );
      _edge = p.edge;
      _along = p.along;
      _engaged = false;
      _dragCenter = null;
      _revealController.value = 0;
    } else {
      _freeCenter = null;
      _edge = p.edge;
      _along = p.along.clamp(0.0, 1.0);
      _engaged = p.isEngaged;
      _dragCenter = null;
      _revealController.value = p.isEngaged ? 1 : 0;
    }
  }

  void _applyPeek(DockEdge edge, double along) {
    final resolved = _resolveIfNeeded(
      EdgeDockPlacement.edge(
        kind: EdgeDockKind.edgePeek,
        edge: edge,
        along: along,
      ),
    );
    setState(() => _setPlacementState(resolved));
    _emitPlacement();
  }

  void _applyFloating(Offset center) {
    final resolved = _resolveIfNeeded(
      EdgeDockPlacement.floating(freeCenter: center),
    );
    setState(() => _setPlacementState(resolved));
    _emitPlacement();
  }

  EdgeDockPlacement get _placement {
    if (_isFloating) {
      return EdgeDockPlacement.floating(freeCenter: _freeCenter!);
    }
    return EdgeDockPlacement.edge(
      kind: _engaged ? EdgeDockKind.edgeEngaged : EdgeDockKind.edgePeek,
      edge: _edge,
      along: _along,
    );
  }

  void _emitPlacement() {
    _syncOccupancy();
    widget.onPlacementChanged?.call(_placement);
  }

  Offset get _snappedCenter => dockCircleCenterForSnapped(
        edge: _edge,
        along: _along,
        bounds: widget.bounds,
        diameter: widget.diameter,
      );

  Offset _fullCenterForSnap() => dockCircleCenterForFullCircle(
        edge: _edge,
        along: _along,
        bounds: widget.bounds,
        diameter: widget.diameter,
      );

  Offset _visualCenter({required double reveal}) {
    if (_dragCenter != null) return _dragCenter!;
    if (_freeCenter != null) return _freeCenter!;
    return Offset.lerp(_snappedCenter, _fullCenterForSnap(), reveal.clamp(0.0, 1.0))!;
  }

  void _lockPageScroll() {
    if (_pageScrollLocked) return;
    _pageScrollLocked = true;
    widget.onPointerOccupied?.call(true);
  }

  void _unlockPageScroll() {
    if (!_pageScrollLocked) return;
    _pageScrollLocked = false;
    widget.onPointerOccupied?.call(false);
  }

  /// [fromPull] 为 true 时，露出全圆后调用 [EdgeDockShell.onPullBusiness]。
  Future<void> _engage({bool fromPull = false}) async {
    if (_engaged || _isFloating) return;
    setState(() => _engaged = true);
    await _revealController.forward();
    _emitPlacement();
    // 仅拉满路径可自动业务；点按 engage 永不触发
    if (fromPull) {
      widget.onPullBusiness?.call();
    }
  }

  Future<void> _disengage() async {
    if (!_engaged || _isFloating) return;
    setState(() => _engaged = false);
    await _revealController.reverse();
    _emitPlacement();
  }

  Offset _globalToBoundsLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  double _inwardDelta(Offset delta) {
    return switch (_edge) {
      DockEdge.right => -delta.dx,
      DockEdge.left => delta.dx,
      DockEdge.bottom => -delta.dy,
      DockEdge.top => delta.dy,
    };
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownGlobal = event.position;
    _isDragging = false;
    _inwardAccum = 0;
    _lockPageScroll();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerDownGlobal == null) return;
    final moved = event.position - _pointerDownGlobal!;
    if (!_isDragging && moved.distance > _tapSlop) {
      _isDragging = true;
      setState(() {
        _dragCenter ??= _visualCenter(reveal: _revealController.value);
      });
    }
    if (!_isDragging) return;

    // peek：累计向内拉满 → engage + 可选拉满业务
    if (_isEdgeSemicircle) {
      _inwardAccum += _inwardDelta(event.delta);
      if (_inwardAccum >= widget.pullInThreshold) {
        unawaited(_engage(fromPull: true));
        return;
      }
    }

    final local = _globalToBoundsLocal(event.position);
    setState(() {
      _dragCenter = clampDockCenterForDrag(
        local,
        widget.bounds,
        diameter: widget.diameter,
      );
    });
  }

  Future<void> _finishDrag() async {
    final center = _dragCenter;
    if (center == null) return;
    final clamped = clampDockCenterForDrag(
      center,
      widget.bounds,
      diameter: widget.diameter,
    );
    late final EdgeDockPlacement desired;
    if (dockShouldSnapToEdge(
      clamped,
      widget.bounds,
      allowTopBottom: widget.allowTopBottom,
      diameter: widget.diameter,
    )) {
      final snap = snapDockToNearestEdge(
        clamped,
        widget.bounds,
        allowTopBottom: widget.allowTopBottom,
        diameter: widget.diameter,
      );
      desired = EdgeDockPlacement.edge(
        kind: EdgeDockKind.edgePeek,
        edge: snap.edge,
        along: snap.along,
      );
    } else {
      desired = EdgeDockPlacement.floating(freeCenter: clamped);
    }
    final resolved = _resolveIfNeeded(desired);
    setState(() => _setPlacementState(resolved));
    _emitPlacement();
  }

  void _onPointerUp(PointerUpEvent event) {
    final wasDragging = _isDragging;
    _pointerDownGlobal = null;
    _isDragging = false;
    _unlockPageScroll();

    if (wasDragging) {
      // 若已因累计拉入 engage，dragCenter 可能仍在
      if (_dragCenter != null && !_engaged) {
        unawaited(_finishDrag());
      } else {
        setState(() => _dragCenter = null);
      }
      return;
    }

    if (_isFloating) {
      widget.onInteractiveTap?.call();
      return;
    }
    if (_isEdgeSemicircle) {
      unawaited(_engage());
    } else {
      widget.onInteractiveTap?.call();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownGlobal = null;
    _isDragging = false;
    _inwardAccum = 0;
    _unlockPageScroll();
    if (_dragCenter != null) {
      setState(() => _dragCenter = null);
    }
  }

  Widget _clipPeek(Widget child) {
    if (!_isEdgeSemicircle || _dragCenter != null) return child;
    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: ClipRect(
        child: Align(
          alignment: switch (_edge) {
            DockEdge.right => Alignment.centerLeft,
            DockEdge.left => Alignment.centerRight,
            DockEdge.top => Alignment.bottomCenter,
            DockEdge.bottom => Alignment.topCenter,
          },
          widthFactor:
              _edge == DockEdge.left || _edge == DockEdge.right ? 0.5 : 1.0,
          heightFactor:
              _edge == DockEdge.top || _edge == DockEdge.bottom ? 0.5 : 1.0,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        final reveal = _revealController.value;
        final center = _visualCenter(reveal: reveal);
        final hit = edgeDockHitTargetRect(
          center: center,
          edge: _edge,
          fullCircleHit: _isFloating || _isEdgeFullCircle || _dragCenter != null,
          diameter: widget.diameter,
          hitExpand: widget.hitExpand,
        );
        final handleLeft = center.dx - _radius - hit.left;
        final handleTop = center.dy - _radius - hit.top;

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.showEngagedScrim && _isEdgeFullCircle)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: widget.bottomScrimInset,
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
                        child: _clipPeek(widget.child),
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
}
