import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/event_media_local_store.dart';
import '../data/history_edit_media_item.dart';
import '../data/models.dart';
import '../session/token_expiry.dart';
import '../ucg/data/ucg_media_compress.dart';
import '../ucg/data/ucg_media_picker.dart';
import '../ucg/data/ucg_presign.dart';
import '../ucg/data/ucg_repository.dart';

/// 广场同步帖子正文：第一行「{宝宝名}的{事件名}」，备注非空时第二行。
String formatHistorySquareSyncCaption({
  required String babyNickname,
  required String eventName,
  required String remark,
}) {
  final event = eventName.trim().isEmpty ? '未知事件' : eventName.trim();
  final baby = _squareSyncBabyDisplayName(babyNickname);
  final line1 = '$baby的$event';
  final r = remark.trim();
  if (r.isEmpty) return line1;
  return '$line1\n$r';
}

String _squareSyncBabyDisplayName(String nickname) {
  final n = nickname.trim();
  if (n.isEmpty || n == '未绑定宝宝ID' || n == '待设置') return '宝宝';
  return n;
}

/// 保存时执行 UCG 同步 / 本地缓存 / 删帖副作用。
class HistoryEventSquareSyncResult {
  const HistoryEventSquareSyncResult({
    required this.postId,
    required this.mediaType,
    required this.imageKeys,
    required this.videoKey,
    this.skippedUcg = false,
    this.ucgError,
  });

  final int postId;
  final int mediaType;
  final List<String> imageKeys;
  final String videoKey;
  final bool skippedUcg;
  final String? ucgError;
}

Future<HistoryEventSquareSyncResult> runHistoryEventMediaSideEffects({
  required UcgRepository ucgRepo,
  required String? wxId,
  required String historyId,
  required String babyNickname,
  required String eventName,
  required String remark,
  required List<HistoryEditMediaItem> media,
  required bool syncEnabled,
  required int existingPostId,
}) async {
  final meta = historyEditMediaMetadata(media);
  final effectiveSync = syncEnabled && media.isNotEmpty;
  final caption = formatHistorySquareSyncCaption(
    babyNickname: babyNickname,
    eventName: eventName,
    remark: remark,
  );

  if (effectiveSync) {
    if (!isUcgWxAccountBound(wxId)) {
      return HistoryEventSquareSyncResult(
        postId: existingPostId,
        mediaType: meta.mediaType,
        imageKeys: meta.imageKeys,
        videoKey: meta.videoKey,
        skippedUcg: true,
        ucgError: 'bind_wechat',
      );
    }
    if (media.isEmpty && existingPostId <= 0) {
      return HistoryEventSquareSyncResult(
        postId: 0,
        mediaType: 0,
        imageKeys: const [],
        videoKey: '',
      );
    }
    try {
      final uploaded = await _uploadHistoryMedia(ucgRepo: ucgRepo, media: media);
      if (existingPostId > 0) {
        final post = await ucgRepo.updatePost(
          postId: '$existingPostId',
          text: caption,
          imageKeys: uploaded.imageKeys,
          videoKey: uploaded.videoKey.isEmpty ? null : uploaded.videoKey,
        );
        return HistoryEventSquareSyncResult(
          postId: int.tryParse(post.id) ?? existingPostId,
          mediaType: uploaded.imageKeys.isNotEmpty ? 1 : (uploaded.videoKey.isNotEmpty ? 2 : 0),
          imageKeys: uploaded.imageKeys,
          videoKey: uploaded.videoKey,
        );
      }
      if (uploaded.imageKeys.isEmpty && uploaded.videoKey.isEmpty && caption.trim().isEmpty) {
        return HistoryEventSquareSyncResult(
          postId: 0,
          mediaType: 0,
          imageKeys: const [],
          videoKey: '',
        );
      }
      final post = await ucgRepo.createPost(
        text: caption,
        imageKeys: uploaded.imageKeys,
        videoKey: uploaded.videoKey.isEmpty ? null : uploaded.videoKey,
      );
      return HistoryEventSquareSyncResult(
        postId: int.tryParse(post.id) ?? 0,
        mediaType: uploaded.imageKeys.isNotEmpty ? 1 : (uploaded.videoKey.isNotEmpty ? 2 : 0),
        imageKeys: uploaded.imageKeys,
        videoKey: uploaded.videoKey,
      );
    } catch (e) {
      return HistoryEventSquareSyncResult(
        postId: existingPostId,
        mediaType: meta.mediaType,
        imageKeys: meta.imageKeys,
        videoKey: meta.videoKey,
        ucgError: e.toString(),
      );
    }
  }

  if (existingPostId > 0) {
    try {
      await ucgRepo.deletePost('$existingPostId');
    } catch (e) {
      return HistoryEventSquareSyncResult(
        postId: existingPostId,
        mediaType: meta.mediaType,
        imageKeys: meta.imageKeys,
        videoKey: meta.videoKey,
        ucgError: e.toString(),
      );
    }
  }

  if (!kIsWeb && media.isNotEmpty) {
    final sources = <({String kind, File file})>[];
    for (final item in media) {
      if (item is HistoryEditLocalFile) {
        final file = File(item.path);
        if (await file.exists()) {
          sources.add((kind: item.isVideo ? 'video' : 'image', file: file));
        }
      }
    }
    if (sources.isNotEmpty) {
      await EventMediaLocalStore.persistLocalMedia(historyId: historyId, sourceFiles: sources);
    } else {
      await EventMediaLocalStore.saveEntries(historyId, const []);
    }
  } else if (media.isEmpty) {
    await EventMediaLocalStore.saveEntries(historyId, const []);
  }

  return HistoryEventSquareSyncResult(
    postId: 0,
    mediaType: meta.mediaType,
    imageKeys: const [],
    videoKey: '',
  );
}

Future<({List<String> imageKeys, String videoKey})> _uploadHistoryMedia({
  required UcgRepository ucgRepo,
  required List<HistoryEditMediaItem> media,
}) async {
  final imageKeys = <String>[];
  String videoKey = '';

  for (final item in media) {
    switch (item) {
      case HistoryEditRemoteImage(:final objectKey):
        imageKeys.add(objectKey);
      case HistoryEditRemoteVideo(:final objectKey):
        videoKey = objectKey;
      case HistoryEditLocalFile(:final path, :final isVideo):
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final name = ucgFallbackFileName(isVideo: isVideo, path: path);
        final prepared = isVideo
            ? await ucgPrepareVideoBytes(bytes: bytes, sourcePath: path)
            : bytes;
        final uploaded = await ucgUploadBytes(
          repo: ucgRepo,
          bytes: Uint8List.fromList(prepared),
          fileName: name,
          contentType: ucgContentTypeForFileName(name),
          isVideo: isVideo,
        );
        if (isVideo) {
          videoKey = uploaded.objectKey;
        } else {
          imageKeys.add(uploaded.objectKey);
        }
    }
  }
  return (imageKeys: imageKeys, videoKey: videoKey);
}

HistoryRecord applyMediaFieldsToRecord(
  HistoryRecord record, {
  required int postId,
  required int mediaType,
  required List<String> imageKeys,
  required String videoKey,
}) {
  final p = Map<String, Object?>.from(record.rawPayload);
  p['postId'] = postId;
  p['mediaType'] = mediaType;
  p['imageKeys'] = imageKeys;
  p['videoKey'] = videoKey;
  return HistoryRecord(
    id: record.id,
    createdAt: record.createdAt,
    eventName: record.eventName,
    action: record.action,
    rawPayload: p,
  );
}
