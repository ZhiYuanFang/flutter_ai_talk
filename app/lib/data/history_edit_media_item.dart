import 'dart:io';
import 'dart:typed_data';

import '../config/event_media_local_store.dart';
import '../ucg/data/ucg_media_url.dart';
import 'history_mapper.dart';
import 'models.dart';

/// 历史编辑 Sheet 媒体条目：本地文件 / 远程图片 / 远程视频。
sealed class HistoryEditMediaItem {
  const HistoryEditMediaItem();

  bool get isVideo =>
      this is HistoryEditRemoteVideo ||
      (this is HistoryEditLocalFile && (this as HistoryEditLocalFile).isVideo);

  bool get isImage => !isVideo;
}

class HistoryEditLocalFile extends HistoryEditMediaItem {
  const HistoryEditLocalFile({
    required this.path,
    required this.isVideo,
    this.bytes,
    this.mediaUri,
  });

  final String path;
  final Uint8List? bytes;
  /// Android 相册 `content://` 播放 URI（与 [path] 沙箱副本配合预览）。
  final String? mediaUri;
  @override
  final bool isVideo;
}

class HistoryEditRemoteImage extends HistoryEditMediaItem {
  const HistoryEditRemoteImage({required this.objectKey, this.cdnUrl});

  final String objectKey;
  final String? cdnUrl;

  String get displayUrl => UcgMediaUrl.resolveUrl(objectKey: objectKey, cdnUrl: cdnUrl);
}

class HistoryEditRemoteVideo extends HistoryEditMediaItem {
  const HistoryEditRemoteVideo({required this.objectKey, this.posterUrl});

  final String objectKey;
  final String? posterUrl;

  String get displayUrl => UcgMediaUrl.resolveUrl(objectKey: objectKey, cdnUrl: posterUrl);
}

/// 从 API payload、本地映射合并加载编辑态媒体列表。
Future<List<HistoryEditMediaItem>> loadHistoryEditMediaItems(HistoryRecord record) async {
  final p = record.rawPayload;
  final postId = historyPayloadPostId(p);
  final imageKeys = historyPayloadImageKeys(p);
  final videoKey = historyPayloadVideoKey(p);

  if (postId > 0 && (imageKeys.isNotEmpty || videoKey.isNotEmpty)) {
    if (videoKey.isNotEmpty) {
      return [HistoryEditRemoteVideo(objectKey: videoKey)];
    }
    return imageKeys.map((k) => HistoryEditRemoteImage(objectKey: k)).toList();
  }

  final local = await EventMediaLocalStore.loadEntries(record.id);
  if (local.isEmpty) return const [];

  final out = <HistoryEditMediaItem>[];
  for (final e in local) {
    final file = await EventMediaLocalStore.resolveFile(e.relativePath);
    if (file == null) continue;
    out.add(HistoryEditLocalFile(path: file.path, isVideo: e.isVideo));
  }
  return out;
}

/// 将编辑态媒体转为 API 媒体元数据占位。
({int mediaType, List<String> imageKeys, String videoKey}) historyEditMediaMetadata(
  List<HistoryEditMediaItem> items,
) {
  if (items.isEmpty) {
    return (mediaType: 0, imageKeys: const [], videoKey: '');
  }
  final video = _firstRemoteVideo(items);
  if (video != null) {
    return (mediaType: 2, imageKeys: const [], videoKey: video.objectKey);
  }
  final localVideo = _firstLocalVideo(items);
  if (localVideo != null) {
    return (mediaType: 2, imageKeys: const [], videoKey: '');
  }
  final remoteKeys = items.whereType<HistoryEditRemoteImage>().map((e) => e.objectKey).toList();
  if (remoteKeys.isNotEmpty) {
    return (mediaType: 1, imageKeys: remoteKeys, videoKey: '');
  }
  if (items.any((e) => e is HistoryEditLocalFile && !e.isVideo)) {
    return (mediaType: 1, imageKeys: const [], videoKey: '');
  }
  return (mediaType: 0, imageKeys: const [], videoKey: '');
}

HistoryEditRemoteVideo? _firstRemoteVideo(List<HistoryEditMediaItem> items) {
  for (final item in items) {
    if (item is HistoryEditRemoteVideo) return item;
  }
  return null;
}

HistoryEditLocalFile? _firstLocalVideo(List<HistoryEditMediaItem> items) {
  for (final item in items) {
    if (item is HistoryEditLocalFile && item.isVideo) return item;
  }
  return null;
}

List<File> historyEditLocalFiles(List<HistoryEditMediaItem> items) {
  return items
      .whereType<HistoryEditLocalFile>()
      .map((e) => File(e.path))
      .where((f) => f.existsSync())
      .toList();
}
