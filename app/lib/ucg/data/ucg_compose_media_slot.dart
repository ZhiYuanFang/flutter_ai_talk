import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'ucg_media_compress.dart';
import 'ucg_media_picker.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';

enum UcgComposeMediaSlotStatus { pending, uploading, done, failed }

/// 发布页单条媒体槽：本地预览 + 后台上传 objectKey。
class UcgComposeMediaSlot {
  UcgComposeMediaSlot({
    required this.id,
    this.localPath,
    this.localBytes,
    this.objectKey,
    this.cdnUrl,
    this.isVideo = false,
    this.status = UcgComposeMediaSlotStatus.pending,
  }) : assert(localPath != null || (objectKey != null && objectKey.isNotEmpty));

  final String id;
  final String? localPath;
  final Uint8List? localBytes;
  String? objectKey;
  String? cdnUrl;
  final bool isVideo;
  UcgComposeMediaSlotStatus status;
  Future<void>? uploadFuture;
  var removed = false;

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
  }) {
    return UcgComposeMediaSlot(
      id: id,
      localPath: path,
      localBytes: bytes,
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

/// 后台上传单槽；完成后回调 [onUpdated] 刷新 UI。
Future<void> uploadComposeMediaSlot({
  required UcgRepository repo,
  required UcgComposeMediaSlot slot,
  void Function()? onUpdated,
}) async {
  if (slot.removed || slot.isDone || !slot.needsUpload) return;

  slot.status = UcgComposeMediaSlotStatus.uploading;
  onUpdated?.call();

  try {
    final path = slot.localPath!;
    final Uint8List bytes;
    if (slot.localBytes != null && slot.localBytes!.isNotEmpty) {
      bytes = slot.localBytes!;
    } else if (kIsWeb) {
      throw StateError('web local bytes missing');
    } else {
      final file = File(path);
      if (!await file.exists()) {
        throw StateError('local file missing');
      }
      bytes = await file.readAsBytes();
    }

    final name = ucgFallbackFileName(isVideo: slot.isVideo, path: path);
    final prepared = slot.isVideo
        ? await ucgPrepareVideoBytes(bytes: bytes, sourcePath: path)
        : bytes;
    final uploaded = await ucgUploadBytes(
      repo: repo,
      bytes: Uint8List.fromList(prepared),
      fileName: name,
      contentType: ucgContentTypeForFileName(name),
      isVideo: slot.isVideo,
    );

    if (slot.removed) {
      try {
        await repo.deleteMedia(objectKeys: [uploaded.objectKey]);
      } catch (_) {}
      return;
    }

    slot.objectKey = uploaded.objectKey;
    slot.cdnUrl = uploaded.cdnUrl;
    slot.status = UcgComposeMediaSlotStatus.done;
  } catch (_) {
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
    for (final slot in failed) {
      slot.status = UcgComposeMediaSlotStatus.pending;
      await uploadComposeMediaSlot(repo: repo, slot: slot, onUpdated: onUpdated);
    }
    await _awaitAllSlots(all);
  }

  if (all.any((s) => !s.isDone)) {
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
