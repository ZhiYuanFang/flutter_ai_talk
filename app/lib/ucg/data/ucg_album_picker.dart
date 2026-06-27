import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'ucg_compose_initial_media.dart';
import 'ucg_media_picker.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';
import 'ucg_video_upload.dart';

final _imagePicker = ImagePicker();

/// 将相册所选 asset 上传并返回 compose 预填媒体。
Future<UcgComposeInitialMedia?> ucgUploadAlbumAssets({
  required UcgRepository repo,
  required List<AssetEntity> assets,
}) async {
  if (assets.isEmpty) return null;

  final first = assets.first;
  if (first.type == AssetType.video) {
    if (assets.length > 1) return null;
    final file = await first.file;
    if (file == null) return null;
    final uploaded = await ucgUploadLocalVideo(repo: repo, sourcePath: file.path);
    return UcgComposeInitialMedia(videoKey: uploaded.objectKey);
  }

  final keys = <String>[];
  for (final asset in assets) {
    if (asset.type != AssetType.image) continue;
    final file = await asset.file;
    if (file == null) continue;
    final bytes = await file.readAsBytes();
    final name = ucgFallbackFileName(isVideo: false, path: file.path);
    final uploaded = await ucgUploadBytes(
      repo: repo,
      bytes: bytes,
      fileName: name,
      contentType: ucgContentTypeForFileName(name),
      isVideo: false,
    );
    keys.add(uploaded.objectKey);
  }
  if (keys.isEmpty) return null;
  return UcgComposeInitialMedia(imageKeys: keys);
}

/// Web 降级：仅选本地文件，不上传 OSS。
Future<UcgComposeInitialMedia?> ucgPickMediaWebLocalFallback({
  int maxImages = 9,
}) async {
  final picked = await _imagePicker.pickMultipleMedia(limit: maxImages);
  if (picked.isEmpty) return null;

  var hasImage = false;
  var hasVideo = false;
  for (final f in picked) {
    final mime = f.mimeType ?? '';
    if (mime.startsWith('video/')) {
      hasVideo = true;
    } else {
      hasImage = true;
    }
  }
  if (hasImage && hasVideo) {
    throw UcgAlbumMixedMediaException();
  }

  if (hasVideo) {
    if (picked.length > 1) throw UcgAlbumMixedMediaException();
    final file = picked.first;
    final bytes = await file.readAsBytes();
    return UcgComposeInitialMedia(
      videoLocalPath: file.path,
      videoLocalBytes: bytes,
    );
  }

  final paths = <String>[];
  final bytesList = <Uint8List>[];
  for (final file in picked) {
    paths.add(file.path);
    bytesList.add(await file.readAsBytes());
  }
  return UcgComposeInitialMedia(imageLocalPaths: paths, imageLocalBytes: bytesList);
}

/// Web 降级：系统多选 + 混选拒绝。
Future<UcgComposeInitialMedia?> ucgPickMediaWebFallback({
  required UcgRepository repo,
  int maxImages = 9,
}) async {
  final picked = await _imagePicker.pickMultipleMedia(limit: maxImages);
  if (picked.isEmpty) return null;

  var hasImage = false;
  var hasVideo = false;
  for (final f in picked) {
    final mime = f.mimeType ?? '';
    if (mime.startsWith('video/')) {
      hasVideo = true;
    } else {
      hasImage = true;
    }
  }
  if (hasImage && hasVideo) {
    throw UcgAlbumMixedMediaException();
  }

  if (hasVideo) {
    if (picked.length > 1) throw UcgAlbumMixedMediaException();
    final file = picked.first;
    final bytes = await file.readAsBytes();
    final uploaded = await ucgUploadLocalVideo(
      repo: repo,
      sourcePath: file.path,
      sourceBytes: bytes,
    );
    return UcgComposeInitialMedia(videoKey: uploaded.objectKey);
  }

  final keys = <String>[];
  for (final file in picked) {
    final bytes = await file.readAsBytes();
    final name = ucgFallbackFileName(isVideo: false, path: file.path);
    final uploaded = await ucgUploadBytes(
      repo: repo,
      bytes: bytes,
      fileName: name,
      contentType: ucgContentTypeForFileName(name),
      isVideo: false,
    );
    keys.add(uploaded.objectKey);
  }
  return UcgComposeInitialMedia(imageKeys: keys);
}

class UcgAlbumMixedMediaException implements Exception {}

/// 打开相册选择（原生 push 由 UI 层处理；Web 走降级）。
Future<UcgComposeInitialMedia?> ucgOpenGalleryPick({
  required UcgRepository repo,
  int maxImages = 9,
}) async {
  if (kIsWeb) {
    try {
      return await ucgPickMediaWebFallback(repo: repo, maxImages: maxImages);
    } on UcgAlbumMixedMediaException {
      rethrow;
    }
  }
  return null;
}

String ucgFormatAssetDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
}
