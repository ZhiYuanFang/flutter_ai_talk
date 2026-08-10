import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/event_definition.dart';
import 'event_logo.dart';
import 'history_event_fly_landing.dart';
import 'home_history_timeline_tile.dart';

/// 历史落库飞入：屏中心放大 → 缩小落向 [landing] 锚点。
///
/// 测不到可用锚点时 MUST NOT 开启动画（直接 [onComplete]）。
class HistoryEventFlyOverlay extends StatefulWidget {
  const HistoryEventFlyOverlay({
    super.key,
    required this.event,
    required this.landing,
    required this.onComplete,
  });

  final EventDefinition? event;
  final HistoryEventFlyLanding landing;
  final VoidCallback onComplete;

  @override
  State<HistoryEventFlyOverlay> createState() => _HistoryEventFlyOverlayState();
}

class _HistoryEventFlyOverlayState extends State<HistoryEventFlyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _layerKey = GlobalKey();
  Offset? _localStart;
  Offset? _localEnd;
  var _ready = false;
  var _animationStarted = false;
  var _measureAttempt = 0;
  var _scrollPrimed = false;
  var _abandoned = false;

  static const _popPhaseFraction = 0.32;
  static const _maxMeasureAttempts = 32;
  static const _minLayerExtent = 8.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    SchedulerBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  void _abandon() {
    if (_abandoned || _animationStarted) return;
    _abandoned = true;
    widget.onComplete();
  }

  void _retryMeasure() {
    if (_abandoned || _animationStarted) {
      if (_animationStarted) _updateEndFromAnchor();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  void _updateEndFromAnchor() {
    if (_animationStarted && _controller.value > _popPhaseFraction) return;
    if (!widget.landing.isAnchorVisible) return;
    final anchor = widget.landing.measureGlobalCenter();
    if (anchor == null) return;
    final localEnd = _globalToLayerLocal(anchor);
    if (localEnd == null || !mounted) return;
    if (_localEnd != null && (_localEnd! - localEnd).distance < 4) return;
    setState(() => _localEnd = localEnd);
  }

  Future<void> _measureAndStart() async {
    if (!mounted || _abandoned) return;
    if (_measureAttempt >= _maxMeasureAttempts) {
      _abandon();
      return;
    }
    _measureAttempt++;

    final layerSize = _layerSize;
    if (layerSize == null) {
      _retryMeasure();
      return;
    }

    if (!_scrollPrimed) {
      final ok = await widget.landing.prepare();
      _scrollPrimed = true;
      if (!mounted || _abandoned) return;
      if (!ok) {
        _abandon();
        return;
      }
    }

    final localStart = Offset(layerSize.width / 2, layerSize.height / 2);
    var localEnd = localStart;
    var anchorReady = false;

    anchorReady = widget.landing.isAnchorVisible;
    final anchor = widget.landing.measureGlobalCenter();
    if (anchor != null && anchor.dx.isFinite && anchor.dy.isFinite) {
      final converted = _globalToLayerLocal(anchor);
      if (converted != null) {
        localEnd = converted;
        anchorReady = widget.landing.isAnchorVisible;
      }
    }

    if (!_animationStarted) {
      // 无可用落点：不飞（禁止落回中心冒充）
      if (!anchorReady || (localEnd - localStart).distance < 8) {
        if (_measureAttempt >= _maxMeasureAttempts) {
          _abandon();
          return;
        }
        _retryMeasure();
        return;
      }
      setState(() {
        _localStart = localStart;
        _localEnd = localEnd;
        _ready = true;
      });
      _animationStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.forward(from: 0);
      });
      return;
    }

    if (localEnd != _localEnd) {
      setState(() => _localEnd = localEnd);
    }
    if (!anchorReady && _controller.value < _popPhaseFraction) {
      _retryMeasure();
    }
  }

  @override
  void didUpdateWidget(covariant HistoryEventFlyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.landing != widget.landing) {
      _scrollPrimed = false;
      _updateEndFromAnchor();
      if (!_animationStarted && !_abandoned) {
        _measureAttempt = 0;
        SchedulerBinding.instance
            .addPostFrameCallback((_) => _measureAndStart());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Size? get _layerSize {
    final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.size;
  }

  Offset? _globalToLayerLocal(Offset global) {
    final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    if (box.size.width < _minLayerExtent || box.size.height < _minLayerExtent) {
      return null;
    }
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: _layerKey,
      child: !_ready || _localStart == null || _localEnd == null
          ? const SizedBox.shrink()
          : Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final localStart = _localStart!;
                    final localEnd = _localEnd!;
                    const baseLogo = HomeHistoryTimelineTile.logoSize;
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final peakScale = (screenWidth * 0.5) / baseLogo;

                    final t = _controller.value;
                    late Offset pos;
                    late double scale;
                    if (t <= _popPhaseFraction) {
                      final popT =
                          Curves.easeOut.transform(t / _popPhaseFraction);
                      scale = 1.0 + (peakScale - 1.0) * popT;
                      pos = localStart;
                    } else {
                      final flyRaw =
                          (t - _popPhaseFraction) / (1 - _popPhaseFraction);
                      final flyT = Curves.easeIn.transform(flyRaw);
                      final landT = Curves.bounceOut.transform(flyRaw);
                      pos = Offset.lerp(localStart, localEnd, landT)!;
                      scale = peakScale - (peakScale - 1.0) * flyT;
                    }
                    final visualSize = baseLogo * scale;

                    return Positioned(
                      left: pos.dx - visualSize / 2,
                      top: pos.dy - visualSize / 2,
                      child: IgnorePointer(
                        child: EventLogo(
                          definition: widget.event,
                          size: visualSize,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
