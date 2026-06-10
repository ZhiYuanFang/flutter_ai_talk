import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import 'ucg_media_compress.dart';
import 'ucg_media_limits.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';

final _picker = ImagePicker();

Future<UcgUploadResult> ucgUploadBytes({
  required UcgRepository repo,
  required Uint8List bytes,
  required String fileName,
  required String contentType,
  required bool isVideo,
}) async {
  final prepared = isVideo
      ? bytes
      : await ucgCompressImageBytes(bytes);
  final contentHash = sha256.convert(prepared).toString();
  return repo.uploadMediaBytes(
    isVideo: isVideo,
    fileName: fileName,
    bytes: prepared,
    contentType: contentType,
    contentHash: contentHash,
    transformVersion: kUcgMediaTransformVersion,
  );
}

/// 单张图片（头像等）；Web 上比 [pickMultiImage] 更可靠。
Future<UcgUploadResult?> ucgPickAndUploadSingleImage({
  required UcgRepository repo,
}) async {
  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = ucgFallbackFileName(isVideo: false, path: picked.path);
  return ucgUploadBytes(
    repo: repo,
    bytes: bytes,
    fileName: name,
    contentType: ucgContentTypeForFileName(name),
    isVideo: false,
  );
}

/// 仅拍照返回本地 path，不上传。
Future<String?> ucgCapturePhotoLocalPath() async {
  if (kIsWeb) return null;
  final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  return picked?.path;
}

/// 仅录像返回本地 path，不上传。
Future<String?> ucgCaptureVideoLocalPath() async {
  if (kIsWeb) return null;
  final file = await _picker.pickVideo(
    source: ImageSource.camera,
    maxDuration: UcgMediaLimits.videoMaxDuration,
  );
  return file?.path;
}

Future<UcgUploadResult?> ucgCaptureAndUploadPhoto({
  required UcgRepository repo,
}) async {
  if (kIsWeb) return null;
  final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = ucgFallbackFileName(isVideo: false, path: picked.path);
  return ucgUploadBytes(
    repo: repo,
    bytes: bytes,
    fileName: name,
    contentType: ucgContentTypeForFileName(name),
    isVideo: false,
  );
}

Future<UcgUploadResult?> ucgCaptureAndUploadVideo({
  required UcgRepository repo,
}) async {
  if (kIsWeb) return null;
  return ucgPickAndUploadVideo(repo: repo, source: ImageSource.camera);
}

Future<List<UcgUploadResult>> ucgPickAndUploadImages({
  required UcgRepository repo,
  required int remainingSlots,
  ImageSource source = ImageSource.gallery,
}) async {
  if (remainingSlots <= 0) return const [];
  if (source == ImageSource.camera) {
    final one = await ucgCaptureAndUploadPhoto(repo: repo);
    return one == null ? const [] : [one];
  }
  final picked = await _picker.pickMultiImage(
    limit: remainingSlots,
    imageQuality: 85,
  );
  if (picked.isEmpty) return const [];

  final results = <UcgUploadResult>[];
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
    results.add(uploaded);
  }
  return results;
}

Future<UcgUploadResult?> ucgPickAndUploadVideo({
  required UcgRepository repo,
  ImageSource source = ImageSource.gallery,
}) async {
  final file = await _picker.pickVideo(
    source: source,
    maxDuration: UcgMediaLimits.videoMaxDuration,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final prepared = await ucgPrepareVideoBytes(bytes: bytes, sourcePath: file.path);
  final name = ucgFallbackFileName(isVideo: true, path: file.path);
  return ucgUploadBytes(
    repo: repo,
    bytes: prepared,
    fileName: name,
    contentType: ucgContentTypeForFileName(name),
    isVideo: true,
  );
}

/// 聊天本地选图/选视频结果（不上传）。
class UcgChatLocalPick {
  const UcgChatLocalPick({
    required this.localPath,
    required this.isVideo,
    this.localBytes,
  });

  final String localPath;
  final bool isVideo;
  final Uint8List? localBytes;
}

/// 聊天附件：仅选择本地文件，不上传 OSS。
Future<UcgChatLocalPick?> ucgPickChatMediaLocal({required bool isVideo}) async {
  if (isVideo) {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: UcgMediaLimits.videoMaxDuration,
    );
    if (file == null) return null;
    return UcgChatLocalPick(localPath: file.path, isVideo: true);
  }
  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  return UcgChatLocalPick(localPath: picked.path, isVideo: false, localBytes: bytes);
}

/// 上传聊天已选本地媒体。
Future<UcgUploadResult> ucgUploadChatLocalMedia({
  required UcgRepository repo,
  required String localPath,
  required bool isVideo,
  Uint8List? localBytes,
}) async {
  final Uint8List bytes;
  if (localBytes != null && localBytes.isNotEmpty) {
    bytes = localBytes;
  } else if (kIsWeb) {
    throw StateError('web local bytes missing');
  } else {
    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('local file missing');
    }
    bytes = await file.readAsBytes();
  }
  final name = ucgFallbackFileName(isVideo: isVideo, path: localPath);
  final prepared = isVideo
      ? await ucgPrepareVideoBytes(bytes: bytes, sourcePath: localPath)
      : bytes;
  return ucgUploadBytes(
    repo: repo,
    bytes: Uint8List.fromList(prepared),
    fileName: name,
    contentType: ucgContentTypeForFileName(name),
    isVideo: isVideo,
  );
}

/// 聊天附件：单张图片或单个视频（互斥）。
Future<UcgUploadResult?> ucgPickAndUploadChatMedia({
  required UcgRepository repo,
  required bool isVideo,
}) async {
  if (isVideo) {
    return ucgPickAndUploadVideo(repo: repo);
  }
  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = ucgFallbackFileName(isVideo: false, path: picked.path);
  return ucgUploadBytes(
    repo: repo,
    bytes: bytes,
    fileName: name,
    contentType: ucgContentTypeForFileName(name),
    isVideo: false,
  );
}
