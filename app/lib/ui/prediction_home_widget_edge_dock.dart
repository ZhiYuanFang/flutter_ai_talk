import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/home_widget_dock_store.dart';
import '../data/edge_dock_geometry.dart';
import '../data/edge_dock_occupancy.dart';
import '../home_widget/has_pinned_home_widget.dart';
import '../theme/app_color.dart';
import 'widgets/edge_dock_shell.dart';

/// 预测竖屏桌面小组件入口贴边球：EdgeDock + widgets 图标；点按进 showcase。
class PredictionHomeWidgetEdgeDock extends ConsumerStatefulWidget {
  const PredictionHomeWidgetEdgeDock({
    super.key,
    this.onPointerOccupied,
    this.bottomReserve = 86,
  });

  /// 壳热区指针按下/抬起时通知宿主锁/解锁主页 PageView 横滑。
  final ValueChanged<bool>? onPointerOccupied;

  /// 可拖区域底部预留（避开底栏）。
  final double bottomReserve;

  /// 当前平台是否支持桌面小组件入口。
  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  ConsumerState<PredictionHomeWidgetEdgeDock> createState() =>
      _PredictionHomeWidgetEdgeDockState();
}

class _PredictionHomeWidgetEdgeDockState
    extends ConsumerState<PredictionHomeWidgetEdgeDock>
    with WidgetsBindingObserver {
  final _dockController = EdgeDockController();
  EdgeDockPlacement? _placement;
  var _loaded = false;
  var _pinned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadDockPosition());
    unawaited(_refreshPinned());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dockController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPinned());
    }
  }

  Future<void> _refreshPinned() async {
    final pinned = await hasPinnedHomeWidget();
    if (!mounted) return;
    setState(() => _pinned = pinned);
  }

  Future<void> _loadDockPosition() async {
    final snap = await HomeWidgetDockStore.load();
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

  Future<void> _onPlacementChanged(EdgeDockPlacement p) async {
    _placement = p;
    if (p.isFloating && p.freeCenter != null) {
      await HomeWidgetDockStore.saveFree(p.freeCenter!);
    } else {
      await HomeWidgetDockStore.saveEdge(p.edge, p.along);
    }
    if (mounted) setState(() {});
  }

  String get _label => _pinned ? '查看桌面小组件' : '添加桌面小组件';

  Widget _buildBall(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    final primary = AppColor.primary(context);

    return Semantics(
      button: true,
      label: _label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColor.panelGlassGradient(context),
          border: Border.all(color: onGlass.withValues(alpha: 0.22)),
        ),
        child: SizedBox(
          width: kDefaultEdgeDockDiameter,
          height: kDefaultEdgeDockDiameter,
          child: Icon(
            Icons.widgets_outlined,
            size: 22,
            color: primary,
          ),
        ),
      ),
    );
  }

  /// engaged / floating 时短显钉态文案；peek 不展示。
  Widget? _buildCaptionOverlay(Rect bounds) {
    final p = _placement;
    if (p == null || p.isPeek) return null;

    final center = edgeDockPlacementCenter(
      p,
      bounds: bounds,
      diameter: kDefaultEdgeDockDiameter,
    );
    final radius = kDefaultEdgeDockDiameter / 2;
    final onGlassMuted = AppColor.textOnPanelGlassMuted(context);
    const gap = 6.0;
    const maxCaptionWidth = 140.0;

    final caption = Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(50),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxCaptionWidth),
          child: Text(
            _label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              color: onGlassMuted,
            ),
          ),
        ),
      ),
    );

    if (p.isFloating) {
      return Positioned(
        left: (center.dx - maxCaptionWidth / 2)
            .clamp(0.0, bounds.width - maxCaptionWidth),
        top: center.dy + radius + gap,
        child: caption,
      );
    }

    return switch (p.edge) {
      DockEdge.left => Positioned(
          left: center.dx + radius + gap,
          top: center.dy - 14,
          child: caption,
        ),
      // 锚右缘贴球（勿用 maxWidth 推 left，否则短文案会离球过远）
      DockEdge.right => Positioned(
          right: bounds.width - (center.dx - radius - gap),
          top: center.dy - 14,
          child: caption,
        ),
      DockEdge.top => Positioned(
          left: (center.dx - maxCaptionWidth / 2)
              .clamp(0.0, bounds.width - maxCaptionWidth),
          top: center.dy + radius + gap,
          child: caption,
        ),
      DockEdge.bottom => Positioned(
          left: (center.dx - maxCaptionWidth / 2)
              .clamp(0.0, bounds.width - maxCaptionWidth),
          bottom: bounds.height - center.dy + radius + gap,
          child: caption,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _placement == null) {
      return const SizedBox.expand();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = (constraints.maxHeight - widget.bottomReserve)
            .clamp(0.0, constraints.maxHeight);
        final bounds = Rect.fromLTWH(0, 0, constraints.maxWidth, h);
        final caption = _buildCaptionOverlay(bounds);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            EdgeDockShell(
              bounds: bounds,
              controller: _dockController,
              initialPlacement: _placement!,
              showEngagedScrim: false,
              occupancyId: kEdgeDockOccupancyHomeWidgetId,
              occupancySticky: true,
              onPlacementChanged: (p) => unawaited(_onPlacementChanged(p)),
              onPointerOccupied: widget.onPointerOccupied,
              onInteractiveTap: () => context.push('/widgets/showcase'),
              child: _buildBall(context),
            ),
            if (caption != null) caption,
          ],
        );
      },
    );
  }
}
