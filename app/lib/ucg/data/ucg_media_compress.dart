import 'dart:typed_data';

import 'package:image/image.dart' as img;

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
