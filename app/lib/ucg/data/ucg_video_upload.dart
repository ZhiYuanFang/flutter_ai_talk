import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../../api/app_debug_log.dart';
import 'ucg_media_limits.dart';
import 'ucg_media_url.dart';
import 'ucg_presign.dart';
import 'ucg_repository.dart';
import 'ucg_video_playback.dart';

enum UcgVideoUploadPhase { preparing, uploading }

/// 本地视频 normalize/probe 失败时展示给用户的统一文案。
const kUcgVideoUploadUserFailureMessage = '视频无法处理，请换一段视频或稍后重试';

String _logBasename(String? path) {
  if (path == null || path.isEmpty) return '';
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf('\\');
  final start = slash > backslash ? slash : backslash;
  return start >= 0 ? path.substring(start + 1) : path;
}

/// 取日志末尾（ffmpeg 真实错误通常在尾部，而非 version banner）。
String _logTail(String? text, {int max = 800}) {
  if (text == null || text.isEmpty) return '';
  final flat = text.replaceAll('\n', ' ').trim();
  if (flat.length <= max) return flat;
  return '…${flat.substring(flat.length - max)}';
}

String _ffmpegErrorSummary(String? logs) {
  if (logs == null || logs.isEmpty) return '未知错误';
  final lines = logs.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  const keywords = [
    'Error',
    'error',
    'Invalid',
    'failed',
    'Failure',
    'No such',
    'cannot',
    'Could not',
    'Unrecognized',
    'Unknown',
    'not found',
  ];
  for (var i = lines.length - 1; i >= 0; i--) {
    final line = lines[i];
    if (line.contains('ffmpeg version')) continue;
    if (line.contains('Copyright (c)')) continue;
    if (keywords.any(line.contains)) {
      return line.length > 400 ? '${line.substring(0, 400)}…' : line;
    }
  }
  final tail = lines.length <= 4 ? lines : lines.sublist(lines.length - 4);
  final joined = tail.join(' | ');
  return joined.length > 500 ? joined.substring(joined.length - 500) : joined;
}

Future<String> _ffmpegFailureDetail(FFmpegSession session) async {
  final rc = await session.getReturnCode();
  final logs = await session.getAllLogsAsString(5000);
  final failStack = await session.getFailStackTrace();
  final parts = <String>[];
  if (rc != null) {
    parts.add('rc=${rc.getValue()}');
  }
  final summary = _ffmpegErrorSummary(logs);
  if (summary.isNotEmpty) parts.add(summary);
  if (failStack != null && failStack.trim().isNotEmpty) {
    parts.add('stack=${_logTail(failStack, max: 300)}');
  }
  return parts.join(' | ');
}

/// 校验本地视频时长与大小（Web 仅 bytes；原生 ffprobe/VideoCompress）。
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

List<String> _normalizeFfmpegArgs({
  required String sourcePath,
  required String outPath,
  required bool hasAudio,
  required int crf,
  required int maxWidth,
}) {
  final maxSec = UcgMediaLimits.videoMaxDuration.inSeconds;
  final scaleFilter = "scale='min($maxWidth,iw)':-2,format=yuv420p,setsar=1";
  final args = <String>['-y', '-i', sourcePath];
  if (hasAudio) {
    args.addAll(['-map', '0:v:0', '-map', '0:a:0']);
  } else {
    args.addAll([
      '-f',
      'lavfi',
      '-i',
      'anullsrc=channel_layout=stereo:sample_rate=44100',
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-shortest',
    ]);
  }
  args.addAll([
    '-vf',
    scaleFilter,
    '-r',
    '30',
    '-t',
    '$maxSec',
    '-c:v',
    'libx264',
    '-profile:v',
    'main',
    '-level',
    '3.1',
    '-pix_fmt',
    'yuv420p',
    '-colorspace',
    'bt709',
    '-color_primaries',
    'bt709',
    '-color_trc',
    'bt709',
    '-color_range',
    'tv',
    '-crf',
    '$crf',
    '-c:a',
    'aac',
    '-b:a',
    '128k',
    '-ar',
    '44100',
    '-ac',
    '2',
    '-movflags',
    '+faststart',
    outPath,
  ]);
  return args;
}

Future<void> _runFfmpegNormalize({
  required String sourcePath,
  required String outPath,
  required bool hasAudio,
  required int crf,
  required int maxWidth,
}) async {
  AppDebugLog.ucgVideo('ffmpeg normalize crf=$crf maxW=$maxWidth hasAudio=$hasAudio');

  final args = _normalizeFfmpegArgs(
    sourcePath: sourcePath,
    outPath: outPath,
    hasAudio: hasAudio,
    crf: crf,
    maxWidth: maxWidth,
  );
  final session = await FFmpegKit.executeWithArguments(args);
  final returnCode = await session.getReturnCode();
  if (!ReturnCode.isSuccess(returnCode)) {
    final logs = await session.getAllLogsAsString(5000);
    final detail = await _ffmpegFailureDetail(session);
    AppDebugLog.ucgVideo('ffmpeg fail $detail tail=${_logTail(logs)}');
    throw StateError('视频处理失败：${_ffmpegErrorSummary(logs)}');
  }
}

Future<String> _ffprobeVideoColorSummary(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final info = session.getMediaInformation();
  final streams = info?.getStreams();
  if (streams == null) return 'color=unknown';
  for (final stream in streams) {
    if (stream.getType() != 'video') continue;
    const keys = [
      'color_space',
      'color_transfer',
      'color_primaries',
      'pix_fmt',
      'profile',
      'level',
    ];
    final parts = <String>[];
    for (final key in keys) {
      final value = stream.getProperty(key);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      parts.add('$key=$text');
    }
    return parts.isEmpty ? 'color=unknown' : parts.join(' ');
  }
  return 'color=unknown';
}

Future<void> _probeNormalizedVideoPlayable(String path) async {
  final sw = Stopwatch()..start();
  try {
    await ucgProbeNormalizedVideoPlayable(path);
    AppDebugLog.ucgVideo('probe ok file=${_logBasename(path)} elapsedMs=${sw.elapsedMilliseconds}');
  } catch (e) {
    AppDebugLog.ucgVideo('probe fail err=$e elapsedMs=${sw.elapsedMilliseconds}');
    throw StateError(kUcgVideoUploadUserFailureMessage);
  }
}

Future<void> _probeCdnVideoPlayable(String url) async {
  final sw = Stopwatch()..start();
  Object? lastErr;
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      await ucgProbeCdnVideoPlayable(url);
      AppDebugLog.ucgVideo(
        'cdn probe ok path=${Uri.tryParse(url)?.path} elapsedMs=${sw.elapsedMilliseconds}',
      );
      return;
    } catch (e) {
      lastErr = e;
      AppDebugLog.ucgVideo(
        'cdn probe fail attempt=${attempt + 1} path=${Uri.tryParse(url)?.path} err=$e',
      );
      if (attempt == 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }
  AppDebugLog.ucgVideo('cdn probe fail err=$lastErr elapsedMs=${sw.elapsedMilliseconds}');
  throw StateError(kUcgVideoUploadUserFailureMessage);
}

/// 原生 ffmpeg：H.264 Main + AAC（无源补静音）+ faststart；超 20MB 降参重试。
Future<Uint8List> ucgNormalizeVideoNative(String sourcePath) async {
  if (kIsWeb) {
    throw StateError('Web 端不支持客户端 ffmpeg');
  }
  final totalSw = Stopwatch()..start();
  final resolved = await ucgResolveVideoSourcePath(sourcePath) ?? sourcePath;
  AppDebugLog.ucgVideo('normalize start file=${_logBasename(resolved)}');
  try {
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
      final attemptSw = Stopwatch()..start();
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
      final colorSummary = await _ffprobeVideoColorSummary(outPath);
      AppDebugLog.ucgVideo(
        'normalize colors $colorSummary file=${_logBasename(outPath)} '
        'crf=${attempt.crf} maxW=${attempt.maxWidth}',
      );
      await _probeNormalizedVideoPlayable(outPath);
      final outBytes = await outFile.readAsBytes();
      lastBytes = outBytes;
      AppDebugLog.ucgVideo(
        'normalize attempt crf=${attempt.crf} maxW=${attempt.maxWidth} '
        'outBytes=${outBytes.length} elapsedMs=${attemptSw.elapsedMilliseconds}',
      );
      if (outBytes.length <= UcgMediaLimits.videoMaxBytes) {
        await _deleteFileIfExists(outPath);
        AppDebugLog.ucgVideo(
          'normalize ok bytes=${outBytes.length} hasAudio=$hasAudio '
          'elapsedMs=${totalSw.elapsedMilliseconds}',
        );
        return outBytes;
      }
    }

    await _deleteFileIfExists(outPath);
    if (lastBytes != null && lastBytes.length <= UcgMediaLimits.serverMaxBytes) {
      AppDebugLog.ucgVideo(
        'normalize ok bytes=${lastBytes.length} hasAudio=$hasAudio '
        'elapsedMs=${totalSw.elapsedMilliseconds} overTarget=true',
      );
      return lastBytes;
    }
    throw StateError(
      '视频处理后仍超过 ${(UcgMediaLimits.videoMaxBytes / (1024 * 1024)).toStringAsFixed(0)}MB 限制',
    );
  } catch (e) {
    AppDebugLog.ucgVideo(
      'normalize fail: $e elapsedMs=${totalSw.elapsedMilliseconds}',
    );
    rethrow;
  }
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

  try {
    if (kIsWeb) {
      final bytes = sourceBytes;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('web local bytes missing');
      }
      await ucgValidateVideoSource(path: sourcePath, bytes: bytes);
      onPhase?.call(UcgVideoUploadPhase.uploading);
      AppDebugLog.ucgVideo('upload start transform=v1 bytes=${bytes.length}');
      final result = await repo.uploadMediaBytes(
        isVideo: true,
        fileName: name,
        bytes: bytes,
        contentType: ucgContentTypeForFileName(name),
        contentHash: sha256.convert(bytes).toString(),
        transformVersion: kUcgMediaTransformVersionVideoWeb,
      );
      AppDebugLog.ucgVideo(
        'upload ok transform=v1 bytes=${bytes.length} objectKey=${result.objectKey}',
      );
      return result;
    }

    onPhase?.call(UcgVideoUploadPhase.preparing);
    final normalized = await ucgNormalizeVideoNative(sourcePath);
    onPhase?.call(UcgVideoUploadPhase.uploading);
    AppDebugLog.ucgVideo('upload start transform=v2 bytes=${normalized.length}');
    final result = await repo.uploadMediaBytes(
      isVideo: true,
      fileName: name,
      bytes: normalized,
      contentType: ucgContentTypeForFileName(name),
      contentHash: sha256.convert(normalized).toString(),
      transformVersion: kUcgMediaTransformVersionVideoNative,
    );
    AppDebugLog.ucgVideo(
      'upload ok transform=v2 bytes=${normalized.length} objectKey=${result.objectKey}',
    );
    final playUrl = UcgMediaUrl.videoPlayUrl(objectKey: result.objectKey, cdnUrl: result.cdnUrl);
    if (playUrl.isNotEmpty) {
      await _probeCdnVideoPlayable(playUrl);
    }
    return result;
  } catch (e) {
    AppDebugLog.ucgVideo('upload fail file=${_logBasename(sourcePath)} err=$e');
    rethrow;
  }
}
