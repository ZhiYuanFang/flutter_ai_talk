import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';

import 'ucg_media_limits.dart';

/// 若 [bytes] 超过 [maxBytes]，逐步降质量/缩放直至满足上限；无法压到目标则抛错。
Future<Uint8List> ucgCompressImageBytes(
  Uint8List bytes, {
  int maxBytes = UcgMediaLimits.imageMaxBytes,
}) async {
  if (bytes.length <= maxBytes) return bytes;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('无法解析图片，请选择 JPG/PNG 格式');
  }

  Uint8List? best;
  for (final scale in [1.0, 0.85, 0.7, 0.55, 0.4, 0.3]) {
    final resized = scale >= 0.99
        ? decoded
        : img.copyResize(
            decoded,
            width: (decoded.width * scale).round().clamp(64, decoded.width),
            height: (decoded.height * scale).round().clamp(64, decoded.height),
          );
    for (final quality in [85, 70, 55, 40, 30, 20]) {
      final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (encoded.length <= maxBytes) return encoded;
      if (best == null || encoded.length < best.length) {
        best = encoded;
      }
    }
  }

  if (best != null && best.length <= UcgMediaLimits.serverMaxBytes) {
    return best;
  }
  throw StateError(
    '图片过大，压缩后仍超过 ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 限制',
  );
}

/// 移动端：若视频超过 [maxBytes] 尝试 [VideoCompress]；Web 仅校验大小。
Future<Uint8List> ucgPrepareVideoBytes({
  required Uint8List bytes,
  required String? sourcePath,
  int maxBytes = UcgMediaLimits.videoMaxBytes,
}) async {
  if (bytes.length <= maxBytes) return bytes;

  if (kIsWeb) {
    if (bytes.length <= UcgMediaLimits.serverMaxBytes) return bytes;
    throw StateError(
      'Web 端暂不支持视频压缩，请选择 ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 以内的视频',
    );
  }

  if (sourcePath == null || sourcePath.isEmpty) {
    throw StateError('视频超过 ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)}MB，无法压缩');
  }

  final info = await VideoCompress.compressVideo(
    sourcePath,
    quality: VideoQuality.MediumQuality,
    deleteOrigin: false,
    includeAudio: true,
  );
  if (info?.file == null) {
    throw StateError('视频压缩失败，请选择更小的文件');
  }
  final compressed = await info!.file!.readAsBytes();
  if (compressed.length <= maxBytes) return Uint8List.fromList(compressed);
  if (compressed.length <= UcgMediaLimits.serverMaxBytes) return Uint8List.fromList(compressed);

  final low = await VideoCompress.compressVideo(
    sourcePath,
    quality: VideoQuality.LowQuality,
    deleteOrigin: false,
    includeAudio: true,
  );
  if (low?.file == null) {
    throw StateError('视频压缩后仍超过大小限制');
  }
  final lowBytes = await low!.file!.readAsBytes();
  if (lowBytes.length <= UcgMediaLimits.serverMaxBytes) {
    return Uint8List.fromList(lowBytes);
  }
  throw StateError('视频压缩后仍超过 ${(UcgMediaLimits.serverMaxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 限制');
}
