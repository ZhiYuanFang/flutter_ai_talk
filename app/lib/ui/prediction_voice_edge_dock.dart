import 'dart:async';

import 'package:flutter/material.dart';

import '../config/home_input_dock_store.dart';
import '../data/edge_dock_geometry.dart';
import '../data/edge_dock_occupancy.dart';
import '../theme/app_color.dart';
import 'widgets/edge_dock_shell.dart';

/// 竖屏预测语音监听贴边球：EdgeDockShell + 圆形 mic；peek 无文案，全圆/浮空短显 caption。
class PredictionVoiceEdgeDock extends StatefulWidget {
  const PredictionVoiceEdgeDock({
    super.key,
    required this.statusCaption,
    required this.chatConnected,
    required this.chatListening,
    required this.onListenTap,
    this.onPointerOccupied,
    this.bottomReserve = 86,
  });

  final String statusCaption;
  final bool chatConnected;
  final bool chatListening;
  final VoidCallback onListenTap;

  /// 壳热区指针按下/抬起时通知宿主锁/解锁主页 PageView 横滑。
  final ValueChanged<bool>? onPointerOccupied;

  /// 可拖区域底部预留（避开底栏导航）。
  final double bottomReserve;

  @override
  State<PredictionVoiceEdgeDock> createState() =>
      _PredictionVoiceEdgeDockState();
}

class _PredictionVoiceEdgeDockState extends State<PredictionVoiceEdgeDock> {
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
    final snap = await PredictionVoiceDockStore.load();
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
      await PredictionVoiceDockStore.saveFree(p.freeCenter!);
    } else {
      await PredictionVoiceDockStore.saveEdge(p.edge, p.along);
    }
    if (mounted) setState(() {});
  }

  Widget _buildMicBall(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onGlass = AppColor.textOnPanelGlass(context);
    final onGlassMuted = AppColor.textOnPanelGlassMuted(context);
    final micHot = widget.chatConnected && widget.chatListening;
    final dotColor = widget.chatConnected ? scheme.tertiary : scheme.error;

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
              micHot ? Icons.mic : Icons.mic_none,
              size: 22,
              color: micHot ? scheme.primary : onGlassMuted,
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        AppColor.panelGlassTop(context).withValues(alpha: 0.9),
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// engaged / floating 时在球旁或球下短显状态文案；peek 不展示。
  Widget? _buildCaptionOverlay(Rect bounds) {
    final p = _placement;
    if (p == null || p.isPeek) return null;
    final text = widget.statusCaption.trim();
    if (text.isEmpty) return null;

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 可选内边距
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(50), // 半透明黑色背景
          borderRadius: BorderRadius.circular(4), // 圆角
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxCaptionWidth),
          child: Text(
            text,
            maxLines: 2,
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
      DockEdge.right => Positioned(
          left: (center.dx - radius - gap - maxCaptionWidth)
              .clamp(0.0, bounds.width - maxCaptionWidth),
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
              occupancyId: kEdgeDockOccupancyPredictionVoiceId,
              occupancySticky: true,
              onPlacementChanged: (p) => unawaited(_onPlacementChanged(p)),
              onPointerOccupied: widget.onPointerOccupied,
              onInteractiveTap: widget.onListenTap,
              child: _buildMicBall(context),
            ),
            if (caption != null) caption,
          ],
        );
      },
    );
  }
}
