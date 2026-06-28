import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../api/app_debug_log.dart';
import '../ui/widgets/ucg_compose_local_preview.dart' show ucgReadLocalImageBytes;
import 'ucg_video_playback.dart';
import 'ucg_media_picker.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';
import 'ucg_video_upload.dart';

enum UcgComposeMediaSlotStatus { pending, preparing, uploading, done, failed }

/// 发布页单条媒体槽：本地预览；upload 在发表/润笔/存草稿时触发。
class UcgComposeMediaSlot {
  UcgComposeMediaSlot({
    required this.id,
    this.localPath,
    this.localBytes,
    this.mediaUri,
    this.objectKey,
    this.cdnUrl,
    this.isVideo = false,
    this.status = UcgComposeMediaSlotStatus.pending,
  }) : assert(localPath != null || (objectKey != null && objectKey.isNotEmpty));

  final String id;
  final String? localPath;
  Uint8List? localBytes;
  String? mediaUri;
  String? objectKey;
  String? cdnUrl;
  final bool isVideo;
  UcgComposeMediaSlotStatus status;
  Future<void>? uploadFuture;
  var removed = false;
  int? videoWidth;
  int? videoHeight;

  bool get isDone =>
      status == UcgComposeMediaSlotStatus.done &&
      objectKey != null &&
      objectKey!.isNotEmpty;

  bool get needsUpload =>
      !removed &&
      !isDone &&
      localPath != null &&
      localPath!.isNotEmpty;

  static UcgComposeMediaSlot remoteImage({
    required String objectKey,
    String? cdnUrl,
  }) {
    return UcgComposeMediaSlot(
      id: 'remote_img_$objectKey',
      objectKey: objectKey,
      cdnUrl: cdnUrl,
      status: UcgComposeMediaSlotStatus.done,
    );
  }

  static UcgComposeMediaSlot remoteVideo({required String objectKey}) {
    return UcgComposeMediaSlot(
      id: 'remote_vid_$objectKey',
      objectKey: objectKey,
      isVideo: true,
      status: UcgComposeMediaSlotStatus.done,
    );
  }

  static UcgComposeMediaSlot localFile({
    required String id,
    required String path,
    required bool isVideo,
    Uint8List? bytes,
    String? mediaUri,
  }) {
    return UcgComposeMediaSlot(
      id: id,
      localPath: path,
      localBytes: bytes,
      mediaUri: mediaUri,
      isVideo: isVideo,
      status: UcgComposeMediaSlotStatus.pending,
    );
  }
}

int _slotCounter = 0;

String nextComposeSlotId() {
  _slotCounter += 1;
  return 'compose_slot_${DateTime.now().microsecondsSinceEpoch}_$_slotCounter';
}

String _composeLogBasename(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf('\\');
  final start = slash > backslash ? slash : backslash;
  return start >= 0 ? path.substring(start + 1) : path;
}

/// 后台上传单槽；完成后回调 [onUpdated] 刷新 UI。
Future<void> uploadComposeMediaSlot({
  required UcgRepository repo,
  required UcgComposeMediaSlot slot,
  void Function()? onUpdated,
}) async {
  if (slot.removed || slot.isDone || !slot.needsUpload) return;

  final path = slot.localPath!;
  AppDebugLog.ucgCompose(
    'compose slot start isVideo=${slot.isVideo} slotId=${slot.id} file=${_composeLogBasename(path)}',
  );

  try {
    final UcgUploadResult uploaded;
    if (slot.isVideo) {
      uploaded = await ucgUploadLocalVideo(
        repo: repo,
        sourcePath: path,
        sourceBytes: slot.localBytes,
        onPhase: (phase) {
          if (slot.removed) return;
          AppDebugLog.ucgCompose('compose slot phase ${phase.name} slotId=${slot.id}');
          slot.status = phase == UcgVideoUploadPhase.preparing
              ? UcgComposeMediaSlotStatus.preparing
              : UcgComposeMediaSlotStatus.uploading;
          onUpdated?.call();
        },
      );
    } else {
      slot.status = UcgComposeMediaSlotStatus.uploading;
      onUpdated?.call();

      final Uint8List bytes;
      if (slot.localBytes != null && slot.localBytes!.isNotEmpty) {
        bytes = slot.localBytes!;
      } else if (kIsWeb) {
        throw StateError('web local bytes missing');
      } else {
        var readPath = path;
        var loaded = await ucgReadLocalImageBytes(readPath);
        if ((loaded == null || loaded.isEmpty) && !kIsWeb) {
          final cached = await ucgCacheMediaPath(readPath);
          if (cached != null) {
            readPath = cached;
            loaded = await ucgReadLocalImageBytes(cached);
          }
        }
        if (loaded != null && loaded.isNotEmpty) {
          slot.localBytes = loaded;
          bytes = loaded;
        } else {
          bytes = Uint8List(0);
        }
        if (bytes.isEmpty) {
          throw StateError('local file missing');
        }
      }

      final name = ucgFallbackFileName(isVideo: false, path: path);
      uploaded = await ucgUploadBytes(
        repo: repo,
        bytes: bytes,
        fileName: name,
        contentType: ucgContentTypeForFileName(name),
        isVideo: false,
      );
    }

    if (slot.removed) {
      try {
        await repo.deleteMedia(objectKeys: [uploaded.objectKey]);
      } catch (_) {}
      return;
    }

    slot.objectKey = uploaded.objectKey;
    slot.cdnUrl = uploaded.cdnUrl;
    slot.status = UcgComposeMediaSlotStatus.done;
    AppDebugLog.ucgCompose(
      'compose slot ok slotId=${slot.id} objectKey=${uploaded.objectKey}',
    );
  } catch (e) {
    AppDebugLog.ucgCompose('compose slot fail slotId=${slot.id} err=$e');
    if (!slot.removed) {
      slot.status = UcgComposeMediaSlotStatus.failed;
    }
  } finally {
    onUpdated?.call();
  }
}

void startComposeSlotBackgroundUpload({
  required UcgRepository repo,
  required UcgComposeMediaSlot slot,
  void Function()? onUpdated,
}) {
  if (!slot.needsUpload) return;
  slot.uploadFuture = uploadComposeMediaSlot(
    repo: repo,
    slot: slot,
    onUpdated: onUpdated,
  );
}

/// 等待全部槽上传完成；失败项重试一次。
Future<({List<String> imageKeys, String? videoKey})> ensureComposeMediaUploaded({
  required UcgRepository repo,
  required List<UcgComposeMediaSlot> imageSlots,
  UcgComposeMediaSlot? videoSlot,
  void Function()? onUpdated,
}) async {
  final all = <UcgComposeMediaSlot>[
    ...imageSlots.where((s) => !s.removed),
    if (videoSlot != null && !videoSlot.removed) videoSlot,
  ];

  for (final slot in all) {
    if (slot.needsUpload) {
      startComposeSlotBackgroundUpload(repo: repo, slot: slot, onUpdated: onUpdated);
    }
  }

  await _awaitAllSlots(all);

  final failed = all.where((s) => s.status == UcgComposeMediaSlotStatus.failed).toList();
  if (failed.isNotEmpty) {
    AppDebugLog.ucgCompose('compose ensure retry failed=${failed.length}');
    for (final slot in failed) {
      slot.status = UcgComposeMediaSlotStatus.pending;
      await uploadComposeMediaSlot(repo: repo, slot: slot, onUpdated: onUpdated);
    }
    await _awaitAllSlots(all);
  }

  if (all.any((s) => !s.isDone)) {
    final videoFailed = all.any(
      (s) => s.isVideo && s.status == UcgComposeMediaSlotStatus.failed,
    );
    if (videoFailed) {
      throw StateError(kUcgVideoUploadUserFailureMessage);
    }
    final statuses = all.map((s) => '${s.id}:${s.status.name}').join(',');
    AppDebugLog.ucgCompose('compose ensure incomplete statuses=$statuses');
    throw StateError('media upload incomplete');
  }

  final imageKeys = imageSlots
      .where((s) => !s.removed && !s.isVideo)
      .map((s) => s.objectKey!)
      .toList(growable: false);
  final videoKey = videoSlot != null && !videoSlot.removed && videoSlot.isVideo
      ? videoSlot.objectKey
      : null;

  return (imageKeys: imageKeys, videoKey: videoKey);
}

Future<void> _awaitAllSlots(List<UcgComposeMediaSlot> slots) async {
  for (final slot in slots) {
    if (slot.uploadFuture != null) {
      await slot.uploadFuture;
    }
  }
}
