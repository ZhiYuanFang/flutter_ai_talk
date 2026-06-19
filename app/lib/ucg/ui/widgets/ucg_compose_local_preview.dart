import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/ucg_media_url.dart';
import 'ucg_network_image.dart';
import 'ucg_media_viewer.dart';

/// 读取本地图片字节（支持 `content://` / `file://` 与常规路径）。
Future<Uint8List?> ucgReadLocalImageBytes(String path) async {
  if (path.isEmpty || kIsWeb) return null;
  try {
    if (path.startsWith('content://') || path.startsWith('file://')) {
      return await XFile(path).readAsBytes();
    }
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    // 部分机型临时路径已失效，再试一次 XFile。
    return await XFile(path).readAsBytes();
  } catch (_) {}
  return null;
}

/// 发布页本地媒体缩略图：优先 [localBytes]；原生 [Image.file]；Web [Image.memory] / blob [Image.network]。
class UcgComposeLocalPreview extends StatelessWidget {
  const UcgComposeLocalPreview({
    super.key,
    this.localPath,
    this.localBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isVideo = false,
    this.showPlayIcon = true,
  });

  final String? localPath;
  final Uint8List? localBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isVideo;
  final bool showPlayIcon;

  @override
  Widget build(BuildContext context) {
    return _buildImage(context);
  }

  Widget _buildImage(BuildContext context) {
    if (isVideo) {
      final bytes = localBytes;
      if (bytes != null && bytes.isNotEmpty) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => _placeholder(context),
            ),
            if (showPlayIcon)
              Center(
                child: UcgVideoPlayOverlayIcon(
                  size: (width != null && width! < 64)
                      ? 24
                      : (width != null && width! < 120)
                          ? 32
                          : 44,
                ),
              ),
          ],
        );
      }
      return UcgLocalVideoThumb(
        filePath: localPath,
        posterBytes: localBytes,
        width: width,
        height: height,
        fit: fit,
        showPlayIcon: showPlayIcon,
      );
    }
    if (localBytes != null && localBytes!.isNotEmpty) {
      return Image.memory(
        localBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }
    if (kIsWeb) {
      if (localBytes != null && localBytes!.isNotEmpty) {
        return Image.memory(
          localBytes!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(context),
        );
      }
      final path = localPath;
      if (path != null &&
          path.isNotEmpty &&
          (path.startsWith('blob:') || path.startsWith('http'))) {
        return Image.network(
          path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(context),
        );
      }
      return _placeholder(context);
    }

    final path = localPath;
    if (path != null && path.isNotEmpty) {
      if (File(path).existsSync()) {
        return Image.file(
          File(path),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _AsyncLocalPathPreview(
            path: path,
            width: width,
            height: height,
            fit: fit,
            placeholder: () => _placeholder(context),
          ),
        );
      }
      return _AsyncLocalPathPreview(
        path: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: () => _placeholder(context),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.image_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// 异步从路径加载本地图片（`content://`、临时文件等）。
class _AsyncLocalPathPreview extends StatefulWidget {
  const _AsyncLocalPathPreview({
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.placeholder,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function() placeholder;

  @override
  State<_AsyncLocalPathPreview> createState() => _AsyncLocalPathPreviewState();
}

class _AsyncLocalPathPreviewState extends State<_AsyncLocalPathPreview> {
  Uint8List? _bytes;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _AsyncLocalPathPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytes = null;
      _failed = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final bytes = await ucgReadLocalImageBytes(widget.path);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _failed = bytes == null || bytes.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.placeholder(),
      );
    }
    if (_failed) return widget.placeholder();
    return widget.placeholder();
  }
}

/// 远程或本地混合预览（上传完成后优先本地图，网络 precache 后再切换）。
class UcgComposeMediaPreview extends StatefulWidget {
  const UcgComposeMediaPreview({
    super.key,
    this.localPath,
    this.localBytes,
    this.objectKey,
    this.cdnUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isVideo = false,
  });

  final String? localPath;
  final Uint8List? localBytes;
  final String? objectKey;
  final String? cdnUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isVideo;

  @override
  State<UcgComposeMediaPreview> createState() => _UcgComposeMediaPreviewState();
}

class _UcgComposeMediaPreviewState extends State<UcgComposeMediaPreview> {
  var _networkReady = false;

  @override
  void didUpdateWidget(covariant UcgComposeMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objectKey != widget.objectKey || oldWidget.cdnUrl != widget.cdnUrl) {
      _networkReady = false;
      _precacheNetworkIfNeeded();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheNetworkIfNeeded();
    });
  }

  bool get _hasLocalPreview {
    if (widget.isVideo) {
      return widget.localPath != null && widget.localPath!.isNotEmpty;
    }
    if (widget.localBytes != null && widget.localBytes!.isNotEmpty) return true;
    final path = widget.localPath;
    if (path == null || path.isEmpty) return false;
    return true;
  }

  void _precacheNetworkIfNeeded() {
    if (!mounted) return;
    final key = widget.objectKey;
    if (key == null || key.isEmpty || widget.isVideo) return;
    if (_hasLocalPreview && _networkReady) return;
    final url = UcgMediaUrl.resolveUrl(objectKey: key, cdnUrl: widget.cdnUrl);
    if (url.isEmpty) return;
    final provider = NetworkImage(url);
    precacheImage(provider, context).then((_) {
      if (!mounted) return;
      setState(() => _networkReady = true);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.localPath;
    if (widget.isVideo && path != null && path.isNotEmpty) {
      return UcgComposeLocalPreview(
        localPath: path,
        localBytes: widget.localBytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        isVideo: true,
      );
    }

    final key = widget.objectKey;
    final useNetwork = key != null &&
        key.isNotEmpty &&
        (!_hasLocalPreview || _networkReady);

    if (useNetwork) {
      return UcgNetworkImage(
        url: UcgMediaUrl.resolveUrl(objectKey: key, cdnUrl: widget.cdnUrl),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return UcgComposeLocalPreview(
      localPath: widget.localPath,
      localBytes: widget.localBytes,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      isVideo: widget.isVideo,
    );
  }
}
