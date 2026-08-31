import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ucg_square_dock_store.dart';
import '../data/edge_dock_geometry.dart';
import '../data/edge_dock_occupancy.dart';
import '../providers/home_pager.dart';
import '../theme/app_color.dart';
import '../ucg/providers/ucg_providers.dart';
import 'widgets/edge_dock_shell.dart';

/// 预测竖屏广场入口贴边球：EdgeDock + 纯图形；未读红点随贴边换角。
class UcgSquareEdgeDock extends ConsumerStatefulWidget {
  const UcgSquareEdgeDock({
    super.key,
    this.onPointerOccupied,
    this.bottomReserve = 86,
  });

  /// 壳热区指针按下/抬起时通知宿主锁/解锁主页 PageView 横滑。
  final ValueChanged<bool>? onPointerOccupied;

  /// 可拖区域底部预留（避开底栏 / FAB）。
  final double bottomReserve;

  @override
  ConsumerState<UcgSquareEdgeDock> createState() => _UcgSquareEdgeDockState();
}

class _UcgSquareEdgeDockState extends ConsumerState<UcgSquareEdgeDock> {
  final _dockController = EdgeDockController();
  EdgeDockPlacement? _placement;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDockPosition());
  }

  @override
  void dispose() {
    _dockController.dispose();
    super.dispose();
  }

  Future<void> _loadDockPosition() async {
    final snap = await UcgSquareDockStore.load();
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
      await UcgSquareDockStore.saveFree(p.freeCenter!);
    } else {
      await UcgSquareDockStore.saveEdge(p.edge, p.along);
    }
    if (mounted) setState(() {});
  }

  void _onTapOpenSquare() {
    ref.read(homePagerRequestProvider.notifier).requestPage(HomePagerPage.ucg);
  }

  /// 红点落在球内朝屏内角，避免 peek 半圆裁掉。
  Widget _buildUnreadDot(BuildContext context, {required bool show}) {
    if (!show) return const SizedBox.shrink();
    const inset = 10.0;
    final p = _placement;
    // floating 或未知：默认右上
    Alignment corner = Alignment.topRight;
    if (p != null && !p.isFloating) {
      corner = switch (p.edge) {
        DockEdge.right => Alignment.topLeft,
        DockEdge.left => Alignment.topRight,
        DockEdge.top => Alignment.bottomLeft,
        DockEdge.bottom => Alignment.topLeft,
      };
    }
    return Align(
      alignment: corner,
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColor.primary(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColor.panelGlassTop(context).withValues(alpha: 0.9),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareBall(BuildContext context, {required bool showUnread}) {
    final onGlass = AppColor.textOnPanelGlass(context);
    final primary = AppColor.primary(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColor.panelGlassGradient(context),
        border: Border.all(color: onGlass.withValues(alpha: 0.22)),
      ),
      child: SizedBox(
        width: kDefaultEdgeDockDiameter,
        height: kDefaultEdgeDockDiameter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: primary,
            ),
            _buildUnreadDot(context, show: showUnread),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _placement == null) {
      return const SizedBox.expand();
    }
    final showUnread = ref.watch(ucgUnreadCountProvider) > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = (constraints.maxHeight - widget.bottomReserve)
            .clamp(0.0, constraints.maxHeight);
        final bounds = Rect.fromLTWH(0, 0, constraints.maxWidth, h);

        return EdgeDockShell(
          bounds: bounds,
          controller: _dockController,
          initialPlacement: _placement!,
          showEngagedScrim: false,
          occupancyId: kEdgeDockOccupancyUcgSquareId,
          occupancySticky: true,
          onPlacementChanged: (p) => unawaited(_onPlacementChanged(p)),
          onPointerOccupied: widget.onPointerOccupied,
          onInteractiveTap: _onTapOpenSquare,
          child: _buildSquareBall(context, showUnread: showUnread),
        );
      },
    );
  }
}
