import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../theme/ucg_theme.dart';
import 'ucg_network_image.dart';

const _kDismissDistanceThreshold = 120.0;
const _kDismissVelocityThreshold = 800.0;
const _kVerticalDragDominance = 1.2;
const _kTapMovementThreshold = 10.0;
const _kPinchResetDuration = Duration(milliseconds: 220);
const _kMaxConcurrentVideoInits = 2;

/// Limits simultaneous [VideoPlayerController.initialize] calls in scrolling feeds.
final class _UcgVideoInitLimiter {
  _UcgVideoInitLimiter._();

  static var _active = 0;
  static final _waiters = <Completer<void>>[];

  static Future<void> acquire() async {
    if (_active < _kMaxConcurrentVideoInits) {
      _active++;
      return;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  static void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else if (_active > 0) {
      _active--;
    }
  }
}

/// Opens a fullscreen photo lightbox with pinch-zoom ([InteractiveViewer]).
Future<void> showUcgPhotoLightbox(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return Future.value();
  final index = initialIndex.clamp(0, urls.length - 1);
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _UcgPhotoLightbox(urls: urls, initialIndex: index),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _UcgPhotoLightbox extends StatefulWidget {
  const _UcgPhotoLightbox({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_UcgPhotoLightbox> createState() => _UcgPhotoLightboxState();
}

class _UcgPhotoLightboxState extends State<_UcgPhotoLightbox> {
  late final PageController _pageController;
  late int _index;
  var _blockPageScroll = false;
  var _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onScrim = Colors.white.withValues(alpha: 0.92);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: _blockPageScroll
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() {
                _index = i;
                _zoomed = false;
              }),
              itemBuilder: (context, i) => _UcgFullscreenDismissLayer(
                enabled: !_zoomed,
                onDismiss: () => Navigator.of(context).pop(),
                onDragActiveChanged: (active) {
                  if (_blockPageScroll != active) {
                    setState(() => _blockPageScroll = active);
                  }
                },
                child: _ResetZoomPhoto(
                  url: widget.urls[i],
                  onZoomed: (zoomed) {
                    if (_zoomed != zoomed) setState(() => _zoomed = zoomed);
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(Icons.close_rounded, color: onScrim),
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: TextStyle(color: onScrim.withValues(alpha: 0.75), fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pull-down to dismiss with iOS-like translate + fade/scale.
///
/// Uses [Listener] pointer tracking so dismiss/tap do not compete in the gesture
/// arena with child [InteractiveViewer] (photos) or [VideoPlayer] (videos).
/// Optional [onPinch*] handles 2-finger zoom on a nested scale detector.
class _UcgFullscreenDismissLayer extends StatefulWidget {
  const _UcgFullscreenDismissLayer({
    required this.child,
    required this.onDismiss,
    this.enabled = true,
    this.onTap,
    this.onDragActiveChanged,
    this.onPinchStart,
    this.onPinchUpdate,
    this.onPinchEnd,
  });

  final Widget child;
  final VoidCallback onDismiss;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onDragActiveChanged;
  final void Function(ScaleStartDetails details)? onPinchStart;
  final void Function(ScaleUpdateDetails details)? onPinchUpdate;
  final void Function(ScaleEndDetails details)? onPinchEnd;

  bool get _scaleMode =>
      onPinchStart != null || onPinchUpdate != null || onPinchEnd != null;

  @override
  State<_UcgFullscreenDismissLayer> createState() => _UcgFullscreenDismissLayerState();
}

class _UcgFullscreenDismissLayerState extends State<_UcgFullscreenDismissLayer>
    with SingleTickerProviderStateMixin {
  double _dragY = 0;
  var _dragging = false;
  var _moved = false;
  var _pinching = false;
  final _activePointers = <int>{};
  int? _activePointer;
  Offset? _start;
  double _lastVelocityY = 0;
  Duration? _lastMoveTime;
  AnimationController? _anim;

  @override
  void dispose() {
    _anim?.dispose();
    super.dispose();
  }

  void _resetGestureState() {
    _activePointer = null;
    _start = null;
    _dragging = false;
    _moved = false;
    _lastVelocityY = 0;
    _lastMoveTime = null;
  }

  void _cancelDismissDrag() {
    if (!_dragging) return;
    widget.onDragActiveChanged?.call(false);
    unawaited(_springBack());
    _resetGestureState();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled || _pinching) return;
    _activePointers.add(event.pointer);
    if (widget._scaleMode && _activePointers.length > 1) {
      _cancelDismissDrag();
      return;
    }
    if (!widget._scaleMode && _activePointers.length > 1) {
      _cancelDismissDrag();
      return;
    }
    _activePointer ??= event.pointer;
    if (_activePointer != event.pointer) return;
    _start = event.position;
    _moved = false;
    _dragging = false;
    _lastVelocityY = 0;
    _lastMoveTime = null;
    _anim?.stop();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled || _pinching || _activePointer != event.pointer || _start == null) {
      return;
    }

    final delta = event.position - _start!;
    if (!_moved && delta.distance > _kTapMovementThreshold) {
      _moved = true;
    }

    if (!_dragging) {
      final dy = delta.dy;
      final dx = delta.dx.abs();
      if (dy > 0 && dy > dx * _kVerticalDragDominance) {
        _dragging = true;
        widget.onDragActiveChanged?.call(true);
      }
    }

    if (_dragging) {
      final prev = _lastMoveTime;
      if (prev != null) {
        final dt = event.timeStamp - prev;
        if (dt.inMicroseconds > 0) {
          _lastVelocityY = event.delta.dy / dt.inMicroseconds * 1e6;
        }
      }
      _lastMoveTime = event.timeStamp;
      setState(() => _dragY = delta.dy.clamp(0.0, double.infinity));
    }
  }

  void _onPointerEnd() {
    if (_pinching) return;

    if (!_dragging) {
      if (!_moved) widget.onTap?.call();
      _resetGestureState();
      return;
    }

    widget.onDragActiveChanged?.call(false);
    _finishDismiss(_lastVelocityY);
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointer != event.pointer) return;
    _onPointerEnd();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointer != event.pointer) return;
    if (_dragging) {
      widget.onDragActiveChanged?.call(false);
      unawaited(_springBack());
    }
    _resetGestureState();
  }

  void _onPinchStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _pinching = true;
    _anim?.stop();
    widget.onPinchStart?.call(details);
  }

  void _onPinchUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    widget.onPinchUpdate?.call(details);

    if (!widget.enabled) return;
    final delta = details.focalPointDelta;
    if (!_dragging && delta.dy > 0 && delta.dy > delta.dx.abs() * _kVerticalDragDominance) {
      _dragging = true;
      widget.onDragActiveChanged?.call(true);
    }
    if (_dragging) {
      setState(() => _dragY = (_dragY + delta.dy).clamp(0.0, double.infinity));
    }
  }

  void _onPinchEnd(ScaleEndDetails details) {
    if (!_pinching) return;
    widget.onPinchEnd?.call(details);
    _pinching = false;

    if (_dragging) {
      widget.onDragActiveChanged?.call(false);
      _finishDismiss(details.velocity.pixelsPerSecond.dy);
    }
  }

  void _finishDismiss(double velocityY) {
    final dragY = _dragY;
    _resetGestureState();

    if (dragY > _kDismissDistanceThreshold || velocityY > _kDismissVelocityThreshold) {
      unawaited(_animateOut());
    } else {
      unawaited(_springBack());
    }
  }

  Future<void> _animateOut() async {
    final screenH = MediaQuery.sizeOf(context).height;
    final begin = _dragY;
    _anim?.dispose();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    final curved = CurvedAnimation(parent: _anim!, curve: Curves.easeOut);
    void onTick() {
      setState(() => _dragY = begin + (screenH - begin) * curved.value);
    }

    curved.addListener(onTick);
    await _anim!.forward();
    curved.removeListener(onTick);
    if (mounted) widget.onDismiss();
  }

  Future<void> _springBack() async {
    final begin = _dragY;
    if (begin <= 0) return;
    _anim?.dispose();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    final curved = CurvedAnimation(parent: _anim!, curve: Curves.elasticOut);
    void onTick() {
      setState(() => _dragY = begin * (1 - curved.value));
    }

    curved.addListener(onTick);
    await _anim!.forward();
    curved.removeListener(onTick);
    if (mounted) setState(() => _dragY = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final progress = (_dragY / (screenH * 0.35)).clamp(0.0, 1.0);

    final content = Opacity(
      opacity: 1.0 - progress * 0.45,
      child: Transform.translate(
        offset: Offset(0, _dragY),
        child: Transform.scale(
          scale: 1.0 - progress * 0.08,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );

    Widget layered = Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: content,
    );

    if (widget._scaleMode) {
      layered = GestureDetector(
        onScaleStart: _onPinchStart,
        onScaleUpdate: _onPinchUpdate,
        onScaleEnd: _onPinchEnd,
        behavior: HitTestBehavior.deferToChild,
        child: layered,
      );
    }

    return layered;
  }
}

/// Pinch-zoom photo; animates back to identity scale on gesture end.
class _ResetZoomPhoto extends StatefulWidget {
  const _ResetZoomPhoto({required this.url, this.onZoomed});

  final String url;
  final ValueChanged<bool>? onZoomed;

  @override
  State<_ResetZoomPhoto> createState() => _ResetZoomPhotoState();
}

class _ResetZoomPhotoState extends State<_ResetZoomPhoto> with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  AnimationController? _resetAnim;
  var _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _resetAnim?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = (scale - 1.0).abs() > 0.02;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomed?.call(zoomed);
    }
  }

  Future<void> _animateToIdentity() async {
    if (_controller.value.isIdentity()) return;
    _resetAnim?.dispose();
    _resetAnim = AnimationController(vsync: this, duration: _kPinchResetDuration);
    final begin = Matrix4.copy(_controller.value);
    final anim = _resetAnim!;
    void tick() {
      _controller.value = Matrix4Tween(begin: begin, end: Matrix4.identity()).evaluate(
        CurvedAnimation(parent: anim, curve: Curves.easeOut),
      );
    }

    anim.addListener(tick);
    await anim.forward();
    anim.removeListener(tick);
    anim.dispose();
    _resetAnim = null;
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.85,
      maxScale: 4,
      panEnabled: _zoomed,
      scaleEnabled: true,
      onInteractionEnd: (_) => unawaited(_animateToIdentity()),
      child: Center(
        child: UcgNetworkImage(url: widget.url, fit: BoxFit.contain),
      ),
    );
  }
}

/// Feed inline video: client first-frame poster until tap; includes fullscreen expand control.
///
/// Before playback, lazily initializes [VideoPlayerController] (muted, paused at t=0)
/// to show the first frame. On dispose, releases the controller.
///
/// **Web note:** playback requires browser-supported codecs (typically MP4/H.264).
/// CDN video URLs must allow cross-origin fetch; unlike images, HTML `<img>` CORS
/// workarounds do not apply — server `Access-Control-Allow-Origin` may be required.
class UcgInlineVideoPlayer extends StatefulWidget {
  const UcgInlineVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.aspectRatio,
    this.borderRadius = 4,
  });

  final String videoUrl;
  final double aspectRatio;
  final double borderRadius;

  @override
  State<UcgInlineVideoPlayer> createState() => _UcgInlineVideoPlayerState();
}

class _UcgInlineVideoPlayerState extends State<UcgInlineVideoPlayer> {
  VideoPlayerController? _controller;
  var _playing = false;
  var _posterReady = false;
  var _posterFailed = false;
  var _initializingPoster = false;
  var _initializingPlayback = false;
  var _playbackFailed = false;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPoster());
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _controller;
    _controller = null;
    unawaited(c?.dispose());
    super.dispose();
  }

  Uri get _videoUri => Uri.parse(widget.videoUrl);

  Future<void> _loadPoster() async {
    if (_disposed || _initializingPoster || _posterReady) return;
    setState(() {
      _initializingPoster = true;
      _posterFailed = false;
    });
    await _UcgVideoInitLimiter.acquire();
    if (_disposed || _posterReady) {
      _UcgVideoInitLimiter.release();
      if (mounted) setState(() => _initializingPoster = false);
      return;
    }

    await _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(_videoUri);
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      if (_disposed || !mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _posterReady = true;
        _initializingPoster = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!_disposed && mounted) {
        setState(() {
          _initializingPoster = false;
          _posterFailed = true;
        });
      }
    } finally {
      _UcgVideoInitLimiter.release();
    }
  }

  Future<void> _startPlayback() async {
    if (_disposed || _playing || _initializingPlayback) return;
    if (!_posterReady || _controller == null) {
      await _loadPoster();
      if (!_posterReady || _controller == null) {
        if (mounted) setState(() => _playbackFailed = true);
        return;
      }
    }
    setState(() {
      _initializingPlayback = true;
      _playbackFailed = false;
    });

    final controller = _controller!;
    try {
      await controller.setVolume(1);
      await controller.play();
      if (_disposed || !mounted) return;
      setState(() {
        _playing = true;
        _initializingPlayback = false;
      });
    } catch (_) {
      if (!_disposed && mounted) {
        setState(() {
          _initializingPlayback = false;
          _playbackFailed = true;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final position = c.value.position;
    final wasPlaying = c.value.isPlaying;
    await c.pause();
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _UcgVideoFullscreenPage(
          videoUrl: widget.videoUrl,
          initialPosition: position,
          autoPlay: wasPlaying,
        ),
      ),
    );

    if (mounted && wasPlaying) {
      await c.play();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = UcgTheme.primary(context);
    final onScrim = UcgTheme.onPrimary(context);

    if (!_playing) {
      return GestureDetector(
        onTap: _startPlayback,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.14),
                        primary.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
                if (_posterReady && _controller != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: IgnorePointer(child: VideoPlayer(_controller!)),
                      ),
                    ),
                  ),
                if (_initializingPoster || _initializingPlayback)
                  Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primary.withValues(alpha: 0.85),
                      ),
                    ),
                  )
                else if (_posterFailed || _playbackFailed)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      kIsWeb ? 'Web 端暂无法播放该视频' : '视频加载失败，点击重试',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.85)),
                    ),
                  )
                else
                  Icon(Icons.play_circle_filled_rounded, color: primary.withValues(alpha: 0.55), size: 44),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: IgnorePointer(
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    opacity: controller.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: Icon(Icons.play_arrow_rounded, color: onScrim, size: 48),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _VideoControlsBar(
                  controller: controller,
                  onFullscreen: _openFullscreen,
                  onSeek: () {
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoControlsBar extends StatefulWidget {
  const _VideoControlsBar({
    required this.controller,
    required this.onFullscreen,
    required this.onSeek,
    this.fullscreenExit = false,
  });

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;
  final VoidCallback onSeek;
  final bool fullscreenExit;

  @override
  State<_VideoControlsBar> createState() => _VideoControlsBarState();
}

class _VideoControlsBarState extends State<_VideoControlsBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!c.value.isInitialized) return const SizedBox.shrink();

    final duration = c.value.duration;
    final position = c.value.position;
    final maxMs = duration.inMilliseconds.clamp(1, 1 << 31);
    final fg = Colors.white.withValues(alpha: 0.92);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 4, 6),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: fg,
                size: 22,
              ),
              tooltip: c.value.isPlaying ? '暂停' : '播放',
              onPressed: () async {
                if (c.value.isPlaying) {
                  await c.pause();
                } else {
                  await c.play();
                }
                widget.onSeek();
              },
            ),
            Text(_format(position), style: TextStyle(color: fg, fontSize: 11)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: position.inMilliseconds.clamp(0, maxMs).toDouble(),
                  max: maxMs.toDouble(),
                  activeColor: UcgTheme.primary(context),
                  inactiveColor: fg.withValues(alpha: 0.25),
                  onChanged: (v) async {
                    await c.seekTo(Duration(milliseconds: v.round()));
                    widget.onSeek();
                  },
                ),
              ),
            ),
            Text(_format(duration), style: TextStyle(color: fg.withValues(alpha: 0.75), fontSize: 11)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                widget.fullscreenExit ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                color: fg,
                size: 22,
              ),
              tooltip: widget.fullscreenExit ? '退出全屏' : '全屏',
              onPressed: widget.onFullscreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _UcgVideoFullscreenPage extends StatefulWidget {
  const _UcgVideoFullscreenPage({
    required this.videoUrl,
    required this.initialPosition,
    required this.autoPlay,
  });

  final String videoUrl;
  final Duration initialPosition;
  final bool autoPlay;

  @override
  State<_UcgVideoFullscreenPage> createState() => _UcgVideoFullscreenPageState();
}

class _UcgVideoFullscreenPageState extends State<_UcgVideoFullscreenPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  var _ready = false;
  var _failed = false;
  var _disposed = false;
  var _showPlayPauseHint = false;
  Timer? _hintTimer;
  double _pinchScale = 1.0;
  double _basePinchScale = 1.0;
  AnimationController? _pinchResetAnim;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
      unawaited(SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]));
    }
    unawaited(_init());
  }

  Future<void> _init() async {
    await _UcgVideoInitLimiter.acquire();
    if (_disposed) {
      _UcgVideoInitLimiter.release();
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      await controller.seekTo(widget.initialPosition);
      if (widget.autoPlay) await controller.play();
      if (_disposed || !mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
      if (!_disposed && mounted) setState(() => _failed = true);
    } finally {
      _UcgVideoInitLimiter.release();
    }
  }

  Future<void> _restoreSystemChrome() async {
    if (kIsWeb) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    _disposed = true;
    _hintTimer?.cancel();
    _pinchResetAnim?.dispose();
    final c = _controller;
    _controller = null;
    unawaited(c?.dispose());
    unawaited(_restoreSystemChrome());
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    _hintTimer?.cancel();
    if (mounted) {
      setState(() => _showPlayPauseHint = true);
      _hintTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showPlayPauseHint = false);
      });
    }
  }

  Future<void> _exit() async {
    await _restoreSystemChrome();
    if (mounted) Navigator.of(context).pop();
  }

  void _onPinchStart(ScaleStartDetails details) {
    _basePinchScale = _pinchScale;
  }

  void _onPinchUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    setState(() => _pinchScale = (_basePinchScale * details.scale).clamp(0.5, 4.0));
  }

  Future<void> _animatePinchReset() async {
    if ((_pinchScale - 1.0).abs() < 0.02) {
      if (mounted) setState(() => _pinchScale = 1.0);
      return;
    }
    _pinchResetAnim?.dispose();
    _pinchResetAnim = AnimationController(vsync: this, duration: _kPinchResetDuration);
    final begin = _pinchScale;
    final anim = _pinchResetAnim!;
    void tick() {
      if (mounted) {
        setState(() => _pinchScale = begin + (1.0 - begin) * anim.value);
      }
    }

    anim.addListener(tick);
    await anim.forward();
    anim.removeListener(tick);
    anim.dispose();
    _pinchResetAnim = null;
    if (mounted) setState(() => _pinchScale = 1.0);
  }

  void _onPinchEnd(ScaleEndDetails details) {
    unawaited(_animatePinchReset());
  }

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.92);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready && _controller != null)
              Positioned.fill(
                child: _UcgFullscreenDismissLayer(
                  onDismiss: _exit,
                  onTap: _togglePlayPause,
                  onPinchStart: _onPinchStart,
                  onPinchUpdate: _onPinchUpdate,
                  onPinchEnd: _onPinchEnd,
                  child: Center(
                    child: Transform.scale(
                      scale: _pinchScale,
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: IgnorePointer(
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (_failed)
              Center(
                child: Text(
                  kIsWeb ? 'Web 端暂无法播放该视频' : '视频加载失败',
                  style: TextStyle(color: fg.withValues(alpha: 0.75)),
                ),
              )
            else
              Center(child: CircularProgressIndicator(color: UcgTheme.primary(context))),
            if (_ready && _controller != null)
              IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showPlayPauseHint ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: fg,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            if (_ready && _controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _VideoControlsBar(
                  controller: _controller!,
                  onFullscreen: _exit,
                  onSeek: () {
                    if (mounted) setState(() {});
                  },
                  fullscreenExit: true,
                ),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.fullscreen_exit_rounded, color: fg),
                tooltip: '退出全屏',
                onPressed: _exit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
