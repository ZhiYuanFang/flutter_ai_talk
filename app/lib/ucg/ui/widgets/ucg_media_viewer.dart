import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../../api/app_debug_log.dart';
import '../../data/ucg_playback_log.dart';
import '../../data/ucg_video_playback.dart';
import '../../theme/ucg_theme.dart';
import 'ucg_android_local_video.dart';
import 'ucg_compose_local_preview.dart' show ucgReadLocalImageBytes;
import 'ucg_network_image.dart';

const _kDismissDistanceThreshold = 120.0;
const _kDismissVelocityThreshold = 800.0;
const _kVerticalDragDominance = 1.2;
const _kTapMovementThreshold = 10.0;
const _kPinchResetDuration = Duration(milliseconds: 220);
const _kMaxConcurrentVideoInits = 2;
const _kAndroidCodecCooldown = Duration(milliseconds: 500);

int _maxConcurrentVideoInits() {
  if (kIsWeb) return _kMaxConcurrentVideoInits;
  return Platform.isAndroid ? 1 : _kMaxConcurrentVideoInits;
}

/// Limits simultaneous [VideoPlayerController.initialize] calls in scrolling feeds.
final class _UcgVideoInitLimiter {
  _UcgVideoInitLimiter._();

  static var _active = 0;
  static final _waiters = <Completer<void>>[];

  static Future<void> acquire() async {
    if (_active < _maxConcurrentVideoInits()) {
      _active++;
      return;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  static void release() {
    Future<void> finish() async {
      if (!kIsWeb && Platform.isAndroid) {
        await Future<void>.delayed(_kAndroidCodecCooldown);
      }
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete();
      } else if (_active > 0) {
        _active--;
      }
    }
    unawaited(finish());
  }
}

/// 动态列表与 compose 视频封面统一的播放按钮样式。
class UcgVideoPlayOverlayIcon extends StatelessWidget {
  const UcgVideoPlayOverlayIcon({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.play_circle_filled_rounded,
      color: UcgTheme.primary(context).withValues(alpha: 0.55),
      size: size,
    );
  }
}

/// 列表表面视频封面：优先 API snapshot 静态图；CDN 未返回可解码图片时回退 VideoPlayer 首帧。
class UcgVideoSnapshotPoster extends StatefulWidget {
  const UcgVideoSnapshotPoster({
    super.key,
    this.posterUrl,
    this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 4,
    this.fit = BoxFit.cover,
  });

  final String? posterUrl;
  final String? videoUrl;
  final double aspectRatio;
  final double borderRadius;
  final BoxFit fit;

  @override
  State<UcgVideoSnapshotPoster> createState() => _UcgVideoSnapshotPosterState();
}

class _UcgVideoSnapshotPosterState extends State<UcgVideoSnapshotPoster> {
  var _snapshotFailed = false;

  void _onSnapshotFailed() {
    if (_snapshotFailed || widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return;
    }
    setState(() => _snapshotFailed = true);
  }

  Widget _gradientPlaceholder(Color primary) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.14),
            primary.withValues(alpha: 0.04),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = UcgTheme.primary(context);
    final hasPoster = widget.posterUrl != null && widget.posterUrl!.isNotEmpty;

    if (_snapshotFailed && widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      return UcgInlineVideoPlayer(
        videoUrl: widget.videoUrl!,
        aspectRatio: widget.aspectRatio,
        borderRadius: widget.borderRadius,
        posterOnly: true,
      );
    }

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        if (hasPoster)
          UcgNetworkImage(
            url: widget.posterUrl!,
            fit: widget.fit,
            errorBuilder: (_, __, ___) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _onSnapshotFailed();
              });
              return _gradientPlaceholder(primary);
            },
          )
        else
          _gradientPlaceholder(primary),
        const UcgVideoPlayOverlayIcon(),
      ],
    );
  }
}

/// Opens a fullscreen photo lightbox with pinch-zoom ([InteractiveViewer]).
Future<void> showUcgPhotoLightbox(
  BuildContext context, {
  required List<String> urls,
  List<String>? thumbnailUrls,
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return Future.value();
  final index = initialIndex.clamp(0, urls.length - 1);
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => _UcgPhotoLightbox(
        urls: urls,
        thumbnailUrls: thumbnailUrls,
        initialIndex: index,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

bool _lightboxHasDistinctThumbnail(String? thumbnailUrl, String fullUrl) {
  final thumb = thumbnailUrl?.trim();
  if (thumb == null || thumb.isEmpty) return false;
  return thumb != fullUrl;
}

/// Fullscreen pinch-zoom for a single local/remote image.
Future<void> showUcgLocalImageLightbox(
  BuildContext context, {
  String? filePath,
  Uint8List? bytes,
  String? url,
}) {
  if ((filePath == null || filePath.isEmpty) &&
      (bytes == null || bytes.isEmpty) &&
      (url == null || url.isEmpty)) {
    return Future.value();
  }
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => _UcgLocalImageLightbox(
        filePath: filePath,
        bytes: bytes,
        url: url,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Fullscreen video player for network URL or local file path.
Future<void> showUcgVideoFullscreen(
  BuildContext context, {
  String? videoUrl,
  String? filePath,
  String? contentUri,
  Uint8List? posterBytes,
  int? videoWidth,
  int? videoHeight,
  Duration initialPosition = Duration.zero,
  bool autoPlay = true,
}) {
  final hasUrl = videoUrl != null && videoUrl.isNotEmpty;
  final hasFile = filePath != null && filePath.isNotEmpty;
  final hasUri = contentUri != null && contentUri.isNotEmpty;
  if (!hasUrl && !hasFile && !hasUri) return Future.value();

  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => _UcgVideoFullscreenPage(
        videoUrl: hasUrl ? videoUrl : null,
        filePath: hasFile ? filePath : null,
        contentUri: hasUri ? contentUri : null,
        posterBytes: posterBytes,
        videoWidth: videoWidth,
        videoHeight: videoHeight,
        initialPosition: initialPosition,
        autoPlay: autoPlay,
      ),
    ),
  );
}

Future<Uint8List?> _loadAssetImagePreviewBytes(AssetEntity asset) async {
  final file = await asset.loadFile(isOrigin: true) ?? await asset.file;
  if (file != null) {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    } catch (_) {}
  }
  try {
    final bytes = await asset.originBytes;
    if (bytes != null && bytes.isNotEmpty) return bytes;
  } catch (_) {}
  try {
    return await asset.thumbnailDataWithSize(const ThumbnailSize.square(2048));
  } catch (_) {}
  return null;
}

/// Album asset fullscreen preview without changing selection.
Future<void> showUcgAssetPreview(BuildContext context, AssetEntity asset) async {
  if (asset.type == AssetType.video) {
    final mediaUri = await asset.getMediaUrl();
    final file = await asset.loadFile(isOrigin: true) ?? await asset.file;
    var path = file?.path;
    if (path == null || path.isEmpty) {
      path = mediaUri;
    }
    if ((path == null || path.isEmpty) && (mediaUri == null || mediaUri.isEmpty)) {
      return;
    }
    if (!context.mounted) return;
    Uint8List? thumb;
    try {
      thumb = await asset.thumbnailDataWithSize(const ThumbnailSize.square(1080));
    } catch (_) {}
    final dims = await ucgProbeLocalVideoDimensions(
      path ?? '',
      contentUri: mediaUri,
    );
    if (!context.mounted) return;
    await showUcgVideoFullscreen(
      context,
      filePath: path,
      contentUri: mediaUri,
      posterBytes: thumb,
      videoWidth: dims.width,
      videoHeight: dims.height,
    );
    return;
  }

  final bytes = await _loadAssetImagePreviewBytes(asset);
  if (!context.mounted) return;
  if (bytes != null && bytes.isNotEmpty) {
    await showUcgLocalImageLightbox(context, bytes: bytes);
    return;
  }

  final file = await asset.loadFile(isOrigin: true) ?? await asset.file;
  if (file != null && context.mounted) {
    await showUcgLocalImageLightbox(context, filePath: file.path);
  }
}

class _UcgLocalImageLightbox extends StatelessWidget {
  const _UcgLocalImageLightbox({
    this.filePath,
    this.bytes,
    this.url,
  });

  final String? filePath;
  final Uint8List? bytes;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final onScrim = Colors.white.withValues(alpha: 0.92);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _UcgFullscreenDismissLayer(
                onDismiss: () => Navigator.of(context).pop(),
                child: _ResetZoomLocalImage(
                  filePath: filePath,
                  bytes: bytes,
                  url: url,
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
          ],
        ),
      ),
    );
  }
}

class _ResetZoomLocalImage extends StatefulWidget {
  const _ResetZoomLocalImage({
    this.filePath,
    this.bytes,
    this.url,
  });

  final String? filePath;
  final Uint8List? bytes;
  final String? url;

  @override
  State<_ResetZoomLocalImage> createState() => _ResetZoomLocalImageState();
}

class _ResetZoomLocalImageState extends State<_ResetZoomLocalImage>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  AnimationController? _resetAnim;
  Uint8List? _loadedBytes;
  var _loadingPath = false;

  @override
  void initState() {
    super.initState();
    unawaited(_hydratePathBytes());
  }

  @override
  void didUpdateWidget(covariant _ResetZoomLocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.bytes != widget.bytes ||
        oldWidget.url != widget.url) {
      _loadedBytes = null;
      unawaited(_hydratePathBytes());
    }
  }

  Future<void> _hydratePathBytes() async {
    if (widget.bytes != null && widget.bytes!.isNotEmpty) return;
    final path = widget.filePath;
    if (path == null || path.isEmpty || kIsWeb) return;
    if (mounted) setState(() => _loadingPath = true);
    final bytes = await ucgReadLocalImageBytes(path);
    if (!mounted) return;
    setState(() {
      _loadedBytes = bytes;
      _loadingPath = false;
    });
  }

  @override
  void dispose() {
    _resetAnim?.dispose();
    _controller.dispose();
    super.dispose();
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

  Widget _buildImage() {
    final preset = widget.bytes;
    if (preset != null && preset.isNotEmpty) {
      return Image.memory(preset, fit: BoxFit.contain);
    }
    final loaded = _loadedBytes;
    if (loaded != null && loaded.isNotEmpty) {
      return Image.memory(loaded, fit: BoxFit.contain);
    }
    final url = widget.url;
    if (url != null && url.isNotEmpty) {
      return UcgNetworkImage(
        url: url,
        fit: BoxFit.contain,
        showLoadingIndicator: true,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image_outlined, color: Colors.white.withValues(alpha: 0.5), size: 48),
      );
    }
    final path = widget.filePath;
    if (!kIsWeb && path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    if (_loadingPath) {
      return const UcgNetworkImageLoadingIndicator();
    }
    return Icon(Icons.broken_image_outlined, color: Colors.white.withValues(alpha: 0.5), size: 48);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: 4,
      onInteractionEnd: (_) => unawaited(_animateToIdentity()),
      child: Center(child: _buildImage()),
    );
  }
}

/// Local or network video first-frame thumbnail with optional play icon overlay.
class UcgLocalVideoThumb extends StatefulWidget {
  const UcgLocalVideoThumb({
    super.key,
    this.filePath,
    this.posterBytes,
    this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showPlayIcon = true,
  });

  final String? filePath;
  final Uint8List? posterBytes;
  final String? videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showPlayIcon;

  @override
  State<UcgLocalVideoThumb> createState() => _UcgLocalVideoThumbState();
}

class _UcgLocalVideoThumbState extends State<UcgLocalVideoThumb> {
  Uint8List? _thumbBytes;
  var _ready = false;
  var _failed = false;
  var _loading = false;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPoster());
  }

  @override
  void didUpdateWidget(covariant UcgLocalVideoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.posterBytes != widget.posterBytes) {
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _controller;
    _controller = null;
    unawaited(c?.dispose());
    super.dispose();
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _thumbBytes = null;
        _ready = false;
        _failed = false;
        _usePlayerPoster = false;
      });
    }
    final c = _controller;
    _controller = null;
    if (c != null) unawaited(c.dispose());
    await _loadPoster();
  }

  Future<void> _loadPoster() async {
    if (_disposed || _loading || _ready) return;

    final preset = widget.posterBytes;
    if (preset != null && preset.isNotEmpty) {
      if (mounted) {
        setState(() {
          _thumbBytes = preset;
          _ready = true;
          _loading = false;
        });
      }
      return;
    }

    final url = widget.videoUrl;
    if (url != null && url.isNotEmpty) {
      await _loadPosterViaPlayer(url: url);
      return;
    }
    final path = widget.filePath;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    if (mounted) setState(() => _loading = true);
    final bytes = await ucgLoadVideoThumbnailBytes(path);
    if (_disposed || !mounted) return;
    if (bytes != null && bytes.isNotEmpty) {
      setState(() {
        _thumbBytes = bytes;
        _ready = true;
        _loading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  /// 仅网络视频在抽帧不可用时回退 ExoPlayer 首帧。
  Future<void> _loadPosterViaPlayer({String? url}) async {
    if (_disposed) return;
    if (mounted) setState(() => _loading = true);
    await _UcgVideoInitLimiter.acquire();
    if (_disposed) {
      _UcgVideoInitLimiter.release();
      return;
    }

    VideoPlayerController? controller;
    if (url != null && url.isNotEmpty) {
      controller = await ucgCreateVideoPlayerController(videoUrl: url);
    }
    if (controller == null) {
      _UcgVideoInitLimiter.release();
      if (!_disposed && mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
      return;
    }

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
        _ready = true;
        _loading = false;
        _usePlayerPoster = true;
      });
    } catch (_) {
      await controller.dispose();
      if (!_disposed && mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } finally {
      _UcgVideoInitLimiter.release();
    }
  }

  VideoPlayerController? _controller;
  var _usePlayerPoster = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;
    Widget child;
    if (_ready && !_usePlayerPoster && _thumbBytes != null) {
      child = Image.memory(
        _thumbBytes!,
        width: w,
        height: h,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _videoPlaceholder(context),
      );
    } else if (_ready && _usePlayerPoster && _controller != null) {
      child = FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: IgnorePointer(child: VideoPlayer(_controller!)),
        ),
      );
    } else if (_loading) {
      child = Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      );
    } else {
      child = _videoPlaceholder(context);
    }

    if (widget.showPlayIcon) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          child,
          Center(
            child: UcgVideoPlayOverlayIcon(
              size: (w != null && w < 64) ? 24 : (w != null && w < 120) ? 32 : 44,
            ),
          ),
        ],
      );
    }

    if (w != null || h != null) {
      return SizedBox(width: w, height: h, child: child);
    }
    return child;
  }

  Widget _videoPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          _failed ? Icons.videocam_off_outlined : Icons.videocam_rounded,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _UcgPhotoLightbox extends StatefulWidget {
  const _UcgPhotoLightbox({
    required this.urls,
    required this.initialIndex,
    this.thumbnailUrls,
  });

  final List<String> urls;
  final List<String>? thumbnailUrls;
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
              itemBuilder: (context, i) {
                final fullUrl = widget.urls[i];
                final thumb = widget.thumbnailUrls != null && i < widget.thumbnailUrls!.length
                    ? widget.thumbnailUrls![i]
                    : null;
                final zoomPhoto = _lightboxHasDistinctThumbnail(thumb, fullUrl)
                    ? _ProgressiveZoomPhoto(
                        key: ValueKey<String>('prog-$fullUrl'),
                        fullUrl: fullUrl,
                        thumbnailUrl: thumb!,
                        onZoomed: (zoomed) {
                          if (_zoomed != zoomed) setState(() => _zoomed = zoomed);
                        },
                      )
                    : _ResetZoomPhoto(
                        key: ValueKey<String>('full-$fullUrl'),
                        url: fullUrl,
                        onZoomed: (zoomed) {
                          if (_zoomed != zoomed) setState(() => _zoomed = zoomed);
                        },
                      );
                return _UcgFullscreenDismissLayer(
                  enabled: !_zoomed,
                  onDismiss: () => Navigator.of(context).pop(),
                  onDragActiveChanged: (active) {
                    if (_blockPageScroll != active) {
                      setState(() => _blockPageScroll = active);
                    }
                  },
                  child: zoomPhoto,
                );
              },
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
  const _ResetZoomPhoto({super.key, required this.url, this.onZoomed});

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
        child: UcgNetworkImage(
          url: widget.url,
          fit: BoxFit.contain,
          showLoadingIndicator: true,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 48,
          ),
        ),
      ),
    );
  }
}

const _kFullImageFadeDuration = Duration(milliseconds: 180);

/// 先展示缩略图，全分辨率就绪后淡入。
class _ProgressiveZoomPhoto extends StatefulWidget {
  const _ProgressiveZoomPhoto({
    super.key,
    required this.fullUrl,
    required this.thumbnailUrl,
    this.onZoomed,
  });

  final String fullUrl;
  final String thumbnailUrl;
  final ValueChanged<bool>? onZoomed;

  @override
  State<_ProgressiveZoomPhoto> createState() => _ProgressiveZoomPhotoState();
}

class _ProgressiveZoomPhotoState extends State<_ProgressiveZoomPhoto>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  AnimationController? _resetAnim;
  var _zoomed = false;
  var _fullReady = false;
  var _fullFailed = false;
  ImageStream? _fullImageStream;
  ImageStreamListener? _fullImageListener;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformChanged);
    _listenFullImage();
  }

  @override
  void didUpdateWidget(covariant _ProgressiveZoomPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullUrl != widget.fullUrl) {
      _teardownFullListen();
      setState(() {
        _fullReady = false;
        _fullFailed = false;
      });
      _listenFullImage();
    }
  }

  @override
  void dispose() {
    _teardownFullListen();
    _controller.removeListener(_onTransformChanged);
    _resetAnim?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _teardownFullListen() {
    final stream = _fullImageStream;
    final listener = _fullImageListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _fullImageStream = null;
    _fullImageListener = null;
  }

  void _listenFullImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = ucgNetworkImageProvider(widget.fullUrl);
      final stream = provider.resolve(createLocalImageConfiguration(context));
      final listener = ImageStreamListener(
        (ImageInfo _, bool __) {
          if (!mounted || _fullReady) return;
          setState(() => _fullReady = true);
        },
        onError: (_, __) {
          if (!mounted) return;
          setState(() => _fullFailed = true);
        },
      );
      _fullImageStream = stream;
      _fullImageListener = listener;
      stream.addListener(listener);
    });
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

  static Widget _brokenIcon() {
    return Icon(
      Icons.broken_image_outlined,
      color: Colors.white.withValues(alpha: 0.5),
      size: 48,
    );
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
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            UcgNetworkImage(url: widget.thumbnailUrl, fit: BoxFit.contain),
            if (!_fullFailed)
              AnimatedOpacity(
                opacity: _fullReady ? 1 : 0,
                duration: _fullReady ? _kFullImageFadeDuration : Duration.zero,
                curve: Curves.easeOut,
                child: UcgNetworkImage(url: widget.fullUrl, fit: BoxFit.contain),
              )
            else
              Positioned(
                bottom: 24,
                child: _brokenIcon(),
              ),
          ],
        ),
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
    this.posterOnly = false,
    this.posterUrl,
  });

  final String videoUrl;
  final double aspectRatio;
  final double borderRadius;
  /// When true, only loads and displays the first-frame poster; no tap-to-play.
  final bool posterOnly;
  /// 静态封面 URL（OSS snapshot）；传入时跳过网络视频首帧提取。
  final String? posterUrl;

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
  var _staticPosterFailed = false;

  bool get _hasStaticPoster =>
      !_staticPosterFailed &&
      widget.posterUrl != null &&
      widget.posterUrl!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasStaticPoster) {
      unawaited(_loadPoster());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _controller;
    _controller = null;
    unawaited(c?.dispose());
    super.dispose();
  }

  void _onStaticPosterFailed() {
    if (_staticPosterFailed || _disposed) return;
    setState(() => _staticPosterFailed = true);
    unawaited(_loadPoster());
  }

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
    final controller = await ucgCreateVideoPlayerController(videoUrl: widget.videoUrl);
    if (controller == null) {
      _UcgVideoInitLimiter.release();
      if (!_disposed && mounted) {
        setState(() {
          _initializingPoster = false;
          _posterFailed = true;
        });
      }
      return;
    }
    final sw = Stopwatch()..start();
    final logTarget = ucgPlayLogUrl(widget.videoUrl);
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'playback');
      }
      if (_disposed || !mounted) {
        await controller.dispose();
        return;
      }
      AppDebugLog.ucgPlay('play cdn poster ok $logTarget elapsedMs=${sw.elapsedMilliseconds}');
      setState(() {
        _controller = controller;
        _posterReady = true;
        _initializingPoster = false;
      });
    } catch (e) {
      AppDebugLog.ucgPlay(
        'play cdn poster fail $logTarget err=${ucgPlayErrorMessage(e, controller)} '
        'elapsedMs=${sw.elapsedMilliseconds}',
      );
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

  Future<void> _initControllerForPlayback() async {
    if (_disposed || _controller != null) return;
    setState(() {
      _initializingPlayback = true;
      _playbackFailed = false;
    });
    await _UcgVideoInitLimiter.acquire();
    if (_disposed || _controller != null) {
      _UcgVideoInitLimiter.release();
      if (mounted) setState(() => _initializingPlayback = false);
      return;
    }

    final controller = await ucgCreateVideoPlayerController(videoUrl: widget.videoUrl);
    if (controller == null) {
      _UcgVideoInitLimiter.release();
      if (!_disposed && mounted) {
        setState(() {
          _initializingPlayback = false;
          _playbackFailed = true;
        });
      }
      return;
    }
    final sw = Stopwatch()..start();
    final logTarget = ucgPlayLogUrl(widget.videoUrl);
    try {
      await controller.initialize();
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'playback');
      }
      if (_disposed || !mounted) {
        await controller.dispose();
        return;
      }
      AppDebugLog.ucgPlay('play cdn init ok $logTarget elapsedMs=${sw.elapsedMilliseconds}');
      setState(() {
        _controller = controller;
        _initializingPlayback = false;
      });
    } catch (e) {
      AppDebugLog.ucgPlay(
        'play cdn init fail $logTarget err=${ucgPlayErrorMessage(e, controller)} '
        'elapsedMs=${sw.elapsedMilliseconds}',
      );
      await controller.dispose();
      if (!_disposed && mounted) {
        setState(() {
          _initializingPlayback = false;
          _playbackFailed = true;
        });
      }
    } finally {
      _UcgVideoInitLimiter.release();
    }
  }

  Future<void> _startPlayback() async {
    if (_disposed || _playing || _initializingPlayback) return;
    if (_controller == null) {
      await _initControllerForPlayback();
      if (_controller == null) {
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
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'playback');
      }
      if (_disposed || !mounted) return;
      setState(() {
        _playing = true;
        _initializingPlayback = false;
      });
    } catch (e) {
      AppDebugLog.ucgPlay(
        'play cdn play fail ${ucgPlayLogUrl(widget.videoUrl)} '
        'err=${ucgPlayErrorMessage(e, controller)}',
      );
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

  Widget _buildPosterStack(BuildContext context, {required bool showPlayIcon}) {
    final primary = UcgTheme.primary(context);
    return Stack(
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
        if (_hasStaticPoster)
          Positioned.fill(
            child: UcgNetworkImage(
              url: widget.posterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _onStaticPosterFailed();
                });
                return const SizedBox.shrink();
              },
            ),
          )
        else if (_posterReady && _controller != null)
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
        else if (showPlayIcon && !(_posterFailed || _playbackFailed))
          const UcgVideoPlayOverlayIcon(),
      ],
    );
  }

  bool get _inlineFailed => _posterFailed || _playbackFailed;

  Widget _buildInlineFailureOverlay(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final primary = UcgTheme.primary(context);
    final retry = onRetry ?? _startPlayback;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: retry,
            behavior: HitTestBehavior.opaque,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.26)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kIsWeb ? 'Web 端暂无法播放该视频' : '视频加载失败，点击重试',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onScrim = UcgTheme.onPrimary(context);

    if (widget.posterOnly) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: _buildPosterStack(context, showPlayIcon: !_inlineFailed),
              ),
              if (_inlineFailed && widget.videoUrl.isNotEmpty)
                _buildInlineFailureOverlay(context, onRetry: _loadPoster),
            ],
          ),
        ),
      );
    }

    if (!_playing) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: _startPlayback,
                behavior: HitTestBehavior.opaque,
                child: _buildPosterStack(
                  context,
                  showPlayIcon:
                      !_inlineFailed && !_initializingPoster && !_initializingPlayback,
                ),
              ),
              if (_inlineFailed) _buildInlineFailureOverlay(context),
            ],
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
  _UcgVideoFullscreenPage({
    this.videoUrl,
    this.filePath,
    this.contentUri,
    this.posterBytes,
    this.videoWidth,
    this.videoHeight,
    required this.initialPosition,
    required this.autoPlay,
  }) : assert(
          (videoUrl != null && videoUrl.isNotEmpty) ||
              (filePath != null && filePath.isNotEmpty) ||
              (contentUri != null && contentUri.isNotEmpty),
        );

  final String? videoUrl;
  final String? filePath;
  final String? contentUri;
  final Uint8List? posterBytes;
  final int? videoWidth;
  final int? videoHeight;
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

  var _nativeAttempt = 0;

  bool get _useAndroidNative => ucgUseAndroidNativeLocalVideo(
        videoUrl: widget.videoUrl,
        filePath: widget.filePath,
        contentUri: widget.contentUri,
      );

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
    if (!_useAndroidNative) {
      unawaited(_init());
    }
  }

  Future<VideoPlayerController?> _loadLocalController({required bool forceTranscodeOnly}) async {
    final path = widget.filePath ?? '';
    if (path.isEmpty && (widget.contentUri?.isEmpty ?? true)) return null;
    return ucgInitializeLocalVideoPlayer(
      path,
      contentUri: widget.contentUri,
      forceTranscodeOnly: forceTranscodeOnly,
    );
  }

  var _playbackGuardAttached = false;

  void _detachPlaybackGuard() {
    final c = _controller;
    if (c != null && _playbackGuardAttached) {
      c.removeListener(_onPlaybackUpdate);
      _playbackGuardAttached = false;
    }
  }

  void _attachPlaybackGuard(VideoPlayerController controller) {
    _detachPlaybackGuard();
    controller.addListener(_onPlaybackUpdate);
    _playbackGuardAttached = true;
  }

  void _onPlaybackUpdate() {
    final c = _controller;
    if (c == null || !mounted || _failed || !c.value.hasError) return;
    unawaited(_handleRuntimePlaybackError());
  }

  Future<void> _handleRuntimePlaybackError() async {
    if (_disposed || !mounted || _failed) return;
    final failed = _controller;
    if (failed == null) return;
    final url = widget.videoUrl;
    if (url != null && url.isNotEmpty) {
      AppDebugLog.ucgPlay(
        'play cdn runtime fail ${ucgPlayLogUrl(url)} '
        'err=${ucgPlayErrorMessage(null, failed)} posMs=${failed.value.position.inMilliseconds}',
      );
    }
    _detachPlaybackGuard();
    _controller = null;
    await failed.dispose();
    if (!mounted || _disposed) return;
    setState(() {
      _ready = false;
      _failed = true;
    });
  }

  Future<bool> _startPlayback(VideoPlayerController controller) async {
    await controller.seekTo(widget.initialPosition);
    if (widget.autoPlay) await controller.play();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return !controller.value.hasError;
  }

  void _markReady(VideoPlayerController controller) {
    _attachPlaybackGuard(controller);
    setState(() {
      _controller = controller;
      _ready = true;
      _failed = false;
    });
  }

  Future<void> _init() async {
    await _UcgVideoInitLimiter.acquire();
    if (_disposed) {
      _UcgVideoInitLimiter.release();
      return;
    }

    VideoPlayerController? controller;
    final url = widget.videoUrl;
    if (url != null && url.isNotEmpty) {
      final sw = Stopwatch()..start();
      final logTarget = ucgPlayLogUrl(url);
      controller = await ucgCreateVideoPlayerController(videoUrl: url);
      if (controller != null) {
        try {
          await controller.initialize();
          if (controller.value.hasError) {
            throw StateError(controller.value.errorDescription ?? 'playback');
          }
          AppDebugLog.ucgPlay(
            'play cdn fullscreen init ok $logTarget elapsedMs=${sw.elapsedMilliseconds}',
          );
        } catch (e) {
          AppDebugLog.ucgPlay(
            'play cdn fullscreen init fail $logTarget err=${ucgPlayErrorMessage(e, controller)} '
            'elapsedMs=${sw.elapsedMilliseconds}',
          );
          await controller.dispose();
          controller = null;
        }
      } else {
        AppDebugLog.ucgPlay(
          'play cdn fullscreen init fail $logTarget err=no-controller '
          'elapsedMs=${sw.elapsedMilliseconds}',
        );
      }
    } else {
      controller = await _loadLocalController(forceTranscodeOnly: false);
    }

    if (controller == null) {
      _UcgVideoInitLimiter.release();
      if (url != null && url.isNotEmpty && !_disposed && mounted) {
        AppDebugLog.ucgPlay('play cdn fullscreen fail ${ucgPlayLogUrl(url)} err=init-aborted');
      }
      if (!_disposed && mounted) setState(() => _failed = true);
      return;
    }

    try {
      final ok = await _startPlayback(controller);
      if (!ok) throw StateError('playback');
      if (_disposed || !mounted) {
        await controller.dispose();
        return;
      }
      _markReady(controller);
    } catch (_) {
      await controller.dispose();
      controller = await _loadLocalController(forceTranscodeOnly: true);
      if (controller != null) {
        try {
          final ok = await _startPlayback(controller);
          if (ok && !_disposed && mounted) {
            _markReady(controller);
            _UcgVideoInitLimiter.release();
            return;
          }
          await controller.dispose();
        } catch (_) {
          await controller.dispose();
        }
      }
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
    _detachPlaybackGuard();
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
            if (_useAndroidNative && !_failed)
              Positioned.fill(
                child: UcgAndroidLocalVideoView(
                  key: ValueKey(
                    'native-${widget.contentUri}-${widget.filePath}-'
                    '${widget.videoWidth}x${widget.videoHeight}-$_nativeAttempt',
                  ),
                  filePath: widget.filePath,
                  contentUri: widget.contentUri,
                  videoWidth: widget.videoWidth,
                  videoHeight: widget.videoHeight,
                  onFailed: () {
                    if (mounted) setState(() => _failed = true);
                  },
                ),
              )
            else if (_ready && _controller != null)
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.posterBytes != null && widget.posterBytes!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            widget.posterBytes!,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        Icon(Icons.videocam_off_outlined, color: fg.withValues(alpha: 0.5), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        kIsWeb ? 'Web 端暂无法播放该视频' : '视频无法在本机预览',
                        style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '仍可正常选择并上传',
                        style: TextStyle(color: fg.withValues(alpha: 0.55), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _failed = false;
                            _ready = false;
                            _nativeAttempt++;
                          });
                          if (!_useAndroidNative) unawaited(_init());
                        },
                        child: Text('重试', style: TextStyle(color: UcgTheme.primary(context))),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: UcgTheme.primary(context)),
                    if (!kIsWeb && Platform.isAndroid) ...[
                      const SizedBox(height: 16),
                      Text(
                        _useAndroidNative ? '正在加载视频…' : '正在转码预览，请稍候…',
                        style: TextStyle(color: fg.withValues(alpha: 0.65), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
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
