import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../../api/app_debug_log.dart';
import 'ucg_media_limits.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';
import 'ucg_video_playback.dart';

enum UcgVideoUploadPhase { preparing, uploading }

/// 校验本地视频时长与大小（Web 仅 bytes；原生 ffprobe/VideoCompress）。
Future<void> ucgValidateVideoSource({
  required String? path,
  Uint8List? bytes,
}) async {
  if (kIsWeb) {
    if (bytes == null || bytes.isEmpty) {
      throw StateError('无法读取视频');
    }
    if (bytes.length > UcgMediaLimits.serverMaxBytes) {
      throw StateError(
        '视频过大，请选择 ${(UcgMediaLimits.serverMaxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 以内的视频',
      );
    }
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
}

Future<bool> _probeHasAudio(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final info = session.getMediaInformation();
  final streams = info?.getStreams();
  if (streams == null) return false;
  for (final stream in streams) {
    if (stream.getType() == 'audio') return true;
  }
  return false;
}

String _ffmpegPathArg(String path) {
  if (path.contains(' ') || path.contains('"')) {
    return '"${path.replaceAll('"', r'\"')}"';
  }
  return path;
}

Future<void> _runFfmpegNormalize({
  required String sourcePath,
  required String outPath,
  required bool hasAudio,
  required int crf,
  required int maxWidth,
}) async {
  final input = _ffmpegPathArg(sourcePath);
  final output = _ffmpegPathArg(outPath);
  final vf = "scale='min($maxWidth,iw)':-2";

  final String command;
  if (hasAudio) {
    command =
        '-y -i $input -map 0:v:0 -map 0:a:0? -vf $vf -r 30 -t ${UcgMediaLimits.videoMaxDuration.inSeconds} '
        '-c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -crf $crf '
        '-c:a aac -b:a 128k -ar 44100 -ac 2 -movflags +faststart $output';
  } else {
    command =
        '-y -i $input -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 '
        '-map 0:v:0 -map 1:a:0 -shortest -vf $vf -r 30 -t ${UcgMediaLimits.videoMaxDuration.inSeconds} '
        '-c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -crf $crf '
        '-c:a aac -b:a 128k -ar 44100 -ac 2 -movflags +faststart $output';
  }

  if (kDebugMode) {
    AppDebugLog.ucgVideo('ffmpeg normalize crf=$crf maxW=$maxWidth hasAudio=$hasAudio');
  }

  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  if (!ReturnCode.isSuccess(returnCode)) {
    final logs = await session.getAllLogsAsString();
    throw StateError('视频处理失败${logs != null && logs.isNotEmpty ? '：$logs' : ''}');
  }
}

/// 原生 ffmpeg：H.264 Main + AAC（无源补静音）+ faststart；超 20MB 降参重试。
Future<Uint8List> ucgNormalizeVideoNative(String sourcePath) async {
  if (kIsWeb) {
    throw StateError('Web 端不支持客户端 ffmpeg');
  }
  final resolved = await ucgResolveVideoSourcePath(sourcePath) ?? sourcePath;
  await ucgValidateVideoSource(path: resolved);

  final hasAudio = await _probeHasAudio(resolved);
  final dir = await getTemporaryDirectory();
  final outPath = '${dir.path}/ucg_norm_${DateTime.now().microsecondsSinceEpoch}.mp4';

  const attempts = <({int crf, int maxWidth})>[
    (crf: 23, maxWidth: 1280),
    (crf: 28, maxWidth: 960),
  ];

  Uint8List? lastBytes;
  for (final attempt in attempts) {
    await _deleteFileIfExists(outPath);
    await _runFfmpegNormalize(
      sourcePath: resolved,
      outPath: outPath,
      hasAudio: hasAudio,
      crf: attempt.crf,
      maxWidth: attempt.maxWidth,
    );
    final outFile = File(outPath);
    if (!await outFile.exists()) continue;
    final outBytes = await outFile.readAsBytes();
    lastBytes = outBytes;
    if (outBytes.length <= UcgMediaLimits.videoMaxBytes) {
      await _deleteFileIfExists(outPath);
      return outBytes;
    }
  }

  await _deleteFileIfExists(outPath);
  if (lastBytes != null && lastBytes.length <= UcgMediaLimits.serverMaxBytes) {
    return lastBytes;
  }
  throw StateError(
    '视频处理后仍超过 ${(UcgMediaLimits.videoMaxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 限制',
  );
}

Future<void> _deleteFileIfExists(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

/// 本地视频 OSS 上传唯一门闸：validate → normalize（原生）→ hash → upload。
Future<UcgUploadResult> ucgUploadLocalVideo({
  required UcgRepository repo,
  required String sourcePath,
  Uint8List? sourceBytes,
  void Function(UcgVideoUploadPhase phase)? onPhase,
}) async {
  final name = ucgFallbackFileName(isVideo: true, path: sourcePath);

  if (kIsWeb) {
    final bytes = sourceBytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('web local bytes missing');
    }
    await ucgValidateVideoSource(path: sourcePath, bytes: bytes);
    onPhase?.call(UcgVideoUploadPhase.uploading);
    if (kDebugMode) {
      AppDebugLog.ucgVideo('upload web v1 bytes=${bytes.length}');
    }
    return repo.uploadMediaBytes(
      isVideo: true,
      fileName: name,
      bytes: bytes,
      contentType: ucgContentTypeForFileName(name),
      contentHash: sha256.convert(bytes).toString(),
      transformVersion: kUcgMediaTransformVersionVideoWeb,
    );
  }

  onPhase?.call(UcgVideoUploadPhase.preparing);
  final normalized = await ucgNormalizeVideoNative(sourcePath);
  onPhase?.call(UcgVideoUploadPhase.uploading);
  if (kDebugMode) {
    AppDebugLog.ucgVideo('upload native v2 bytes=${normalized.length}');
  }
  return repo.uploadMediaBytes(
    isVideo: true,
    fileName: name,
    bytes: normalized,
    contentType: ucgContentTypeForFileName(name),
    contentHash: sha256.convert(normalized).toString(),
    transformVersion: kUcgMediaTransformVersionVideoNative,
  );
}
