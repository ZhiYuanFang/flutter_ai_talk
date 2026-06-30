import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_compress/video_compress.dart';

import '../../api/app_debug_log.dart';
import '../../config/env.dart';
import 'ucg_media_limits.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';
import 'ucg_video_playback.dart';

enum UcgVideoUploadPhase { uploading }

/// 本地视频上传关闭时的用户文案。
const kUcgVideoUploadDisabledMessage = '视频上传暂未开放';

/// 本地视频 validate/upload 失败时展示给用户的统一文案。
const kUcgVideoUploadUserFailureMessage = '视频无法处理，请换一段视频或稍后重试';

String _logBasename(String? path) {
  if (path == null || path.isEmpty) return '';
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf('\\');
  final start = slash > backslash ? slash : backslash;
  return start >= 0 ? path.substring(start + 1) : path;
}

/// 编译期开关关闭时拒绝上传（UI 层亦应隐藏入口）。
void ucgAssertVideoUploadEnabled() {
  if (!AppEnv.ucgVideoUploadEnabled) {
    throw StateError(kUcgVideoUploadDisabledMessage);
  }
}

/// 校验本地视频时长与大小（Web 用 bytes；Native 用 VideoCompress）。
Future<void> ucgValidateVideoSource({
  required String? path,
  Uint8List? bytes,
}) async {
  try {
    if (kIsWeb) {
      if (bytes == null || bytes.isEmpty) {
        throw StateError('无法读取视频');
      }
      if (bytes.length > UcgMediaLimits.serverMaxBytes) {
        throw StateError(
          '视频过大，请选择 ${(UcgMediaLimits.serverMaxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 以内的视频',
        );
      }
      AppDebugLog.ucgVideo('validate ok web bytes=${bytes.length}');
      return;
    }

    if (path == null || path.isEmpty) {
      throw StateError('无法读取视频');
    }
    final resolved = await ucgResolveVideoSourcePath(path) ?? path;
    final info = await VideoCompress.getMediaInfo(resolved);
    final durationMs = info.duration ?? 0;
    if (durationMs > UcgMediaLimits.videoMaxDuration.inMilliseconds + 500) {
      throw StateError('视频时长不能超过 ${UcgMediaLimits.videoMaxDuration.inSeconds} 秒');
    }
    final size = info.filesize ?? 0;
    if (size > UcgMediaLimits.serverMaxBytes) {
      throw StateError(
        '视频过大，请选择 ${(UcgMediaLimits.serverMaxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 以内的视频',
      );
    }
    AppDebugLog.ucgVideo(
      'validate ok file=${_logBasename(resolved)} durationMs=$durationMs size=$size',
    );
  } catch (e) {
    AppDebugLog.ucgVideo('validate fail: $e');
    rethrow;
  }
}

Future<Uint8List> _readVideoBytes({
  required String sourcePath,
  Uint8List? sourceBytes,
}) async {
  if (sourceBytes != null && sourceBytes.isNotEmpty) {
    return sourceBytes;
  }
  if (kIsWeb) {
    throw StateError('web local bytes missing');
  }
  final resolved = await ucgResolveVideoSourcePath(sourcePath) ?? sourcePath;
  final file = File(resolved);
  if (!await file.exists()) {
    throw StateError('无法读取视频');
  }
  return file.readAsBytes();
}

/// 本地视频 OSS 上传唯一门闸：validate → raw bytes → v1 upload（全平台与 Web 一致）。
Future<UcgUploadResult> ucgUploadLocalVideo({
  required UcgRepository repo,
  required String sourcePath,
  Uint8List? sourceBytes,
  void Function(UcgVideoUploadPhase phase)? onPhase,
}) async {
  ucgAssertVideoUploadEnabled();

  final name = ucgFallbackFileName(isVideo: true, path: sourcePath);

  try {
    final bytes = await _readVideoBytes(sourcePath: sourcePath, sourceBytes: sourceBytes);
    await ucgValidateVideoSource(path: sourcePath, bytes: bytes);
    onPhase?.call(UcgVideoUploadPhase.uploading);
    AppDebugLog.ucgVideo('upload start transform=v1 bytes=${bytes.length}');
    final result = await repo.uploadMediaBytes(
      isVideo: true,
      fileName: name,
      bytes: bytes,
      contentType: ucgContentTypeForFileName(name),
      contentHash: sha256.convert(bytes).toString(),
      transformVersion: kUcgMediaTransformVersionVideo,
    );
    AppDebugLog.ucgVideo(
      'upload ok transform=v1 bytes=${bytes.length} objectKey=${result.objectKey}',
    );
    return result;
  } catch (e) {
    AppDebugLog.ucgVideo('upload fail file=${_logBasename(sourcePath)} err=$e');
    rethrow;
  }
}
