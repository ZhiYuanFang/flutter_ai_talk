import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/ucg_media_url.dart';
import 'ucg_network_image.dart';
import 'ucg_media_viewer.dart';

/// 发布页本地媒体缩略图：原生 [Image.file]；Web [Image.memory] / blob [Image.network]。
class UcgComposeLocalPreview extends StatelessWidget {
  const UcgComposeLocalPreview({
    super.key,
    this.localPath,
    this.localBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isVideo = false,
  });

  final String? localPath;
  final Uint8List? localBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return _buildImage(context);
  }

  Widget _buildImage(BuildContext context) {
    if (isVideo) {
      return UcgLocalVideoThumb(
        filePath: localPath,
        width: width,
        height: height,
        fit: fit,
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
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
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

/// 远程或本地混合预览（有 objectKey 时优先网络图）。
class UcgComposeMediaPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final path = localPath;
    if (isVideo && path != null && path.isNotEmpty) {
      return UcgComposeLocalPreview(
        localPath: path,
        localBytes: localBytes,
        width: width,
        height: height,
        fit: fit,
        isVideo: true,
      );
    }
    if (objectKey != null && objectKey!.isNotEmpty) {
      return UcgNetworkImage(
        url: UcgMediaUrl.resolveUrl(objectKey: objectKey!, cdnUrl: cdnUrl),
        width: width,
        height: height,
        fit: fit,
      );
    }
    return UcgComposeLocalPreview(
      localPath: localPath,
      localBytes: localBytes,
      width: width,
      height: height,
      fit: fit,
      isVideo: isVideo,
    );
  }
}
