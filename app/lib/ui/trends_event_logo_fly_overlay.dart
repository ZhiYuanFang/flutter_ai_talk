import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/event_definition.dart';
import 'event_logo.dart';

class TrendsEventLogoFlyOverlay extends StatefulWidget {
  const TrendsEventLogoFlyOverlay({
    super.key,
    required this.event,
    required this.targetGlobalCenter,
    required this.baseLogoSize,
    required this.onComplete,
  });

  final EventDefinition event;
  final Offset targetGlobalCenter;
  final double baseLogoSize;
  final VoidCallback onComplete;

  @override
  State<TrendsEventLogoFlyOverlay> createState() => _TrendsEventLogoFlyOverlayState();
}

class _TrendsEventLogoFlyOverlayState extends State<TrendsEventLogoFlyOverlay>
    with SingleTickerProviderStateMixin {
  static const _popPhaseFraction = 0.32;
  static const _minLayerExtent = 8.0;

  late final AnimationController _controller;
  final _layerKey = GlobalKey();
  Offset? _localStart;
  Offset? _localEnd;
  var _ready = false;

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

  void _measureAndStart() {
    if (!mounted) return;
    final layerSize = _layerSize;
    if (layerSize == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _measureAndStart());
      return;
    }
    final localStart = Offset(layerSize.width / 2, layerSize.height / 2);
    final localEnd = _globalToLayerLocal(widget.targetGlobalCenter);
    if (localEnd == null || (localEnd - localStart).distance < 8) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _measureAndStart());
      return;
    }
    setState(() {
      _localStart = localStart;
      _localEnd = localEnd;
      _ready = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward(from: 0);
    });
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
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final peakScale = (screenWidth * 0.5) / widget.baseLogoSize;

                    final t = _controller.value;
                    late Offset pos;
                    late double scale;
                    if (t <= _popPhaseFraction) {
                      final popT = Curves.easeOut.transform(t / _popPhaseFraction);
                      scale = 1.0 + (peakScale - 1.0) * popT;
                      pos = localStart;
                    } else {
                      final flyRaw = (t - _popPhaseFraction) / (1 - _popPhaseFraction);
                      final flyT = Curves.easeIn.transform(flyRaw);
                      final landT = Curves.bounceOut.transform(flyRaw);
                      pos = Offset.lerp(localStart, localEnd, landT)!;
                      scale = peakScale - (peakScale - 1.0) * flyT;
                    }
                    final visualSize = widget.baseLogoSize * scale;

                    return Positioned(
                      left: pos.dx - visualSize / 2,
                      top: pos.dy - visualSize / 2,
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: EventLogo(
                            definition: widget.event,
                            size: visualSize,
                          ),
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
