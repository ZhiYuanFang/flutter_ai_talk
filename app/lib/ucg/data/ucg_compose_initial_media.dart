import 'dart:typed_data';

import '../../data/history_edit_media_item.dart';

/// 发布入口/相册选择后的 compose 预填媒体（本地 path 或已上传 key）。
class UcgComposeInitialMedia {
  const UcgComposeInitialMedia({
    this.imageLocalPaths = const [],
    this.imageLocalBytes = const [],
    this.videoLocalPath,
    this.videoLocalBytes,
    this.imageKeys = const [],
    this.videoKey,
  });

  final List<String> imageLocalPaths;
  /// 与 [imageLocalPaths] 同序；Web 选图时预读 bytes 供预览与上传。
  final List<Uint8List> imageLocalBytes;
  final String? videoLocalPath;
  final Uint8List? videoLocalBytes;
  final List<String> imageKeys;
  final String? videoKey;

  bool get isEmpty =>
      imageLocalPaths.isEmpty &&
      (videoLocalPath == null || videoLocalPath!.isEmpty) &&
      imageKeys.isEmpty &&
      (videoKey == null || videoKey!.isEmpty);

  bool get hasLocal =>
      imageLocalPaths.isNotEmpty ||
      (videoLocalPath != null && videoLocalPath!.isNotEmpty);

  factory UcgComposeInitialMedia.fromHistoryItems(List<HistoryEditMediaItem> items) {
    if (items.isEmpty) return const UcgComposeInitialMedia();
    final video = items.whereType<HistoryEditLocalFile>().where((e) => e.isVideo).firstOrNull;
    if (video != null) {
      return UcgComposeInitialMedia(videoLocalPath: video.path);
    }
    final paths = items
        .whereType<HistoryEditLocalFile>()
        .where((e) => !e.isVideo)
        .map((e) => e.path)
        .toList(growable: false);
    return UcgComposeInitialMedia(imageLocalPaths: paths);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
