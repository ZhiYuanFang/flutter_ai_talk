import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

const _kAndroidCodecCooldown = Duration(milliseconds: 500);

Future<void> _androidCodecCooldown() async {
  if (!kIsWeb && Platform.isAndroid) {
    await Future<void>.delayed(_kAndroidCodecCooldown);
  }
}

void _ucgVideoLog(String message) {
  if (kDebugMode) debugPrint('[ucg_video] $message');
}

bool ucgPathIsMediaUri(String path) =>
    path.startsWith('content://') || path.startsWith('file://');

bool _isAppSandboxPath(String path) =>
    !path.startsWith('/storage/') && !ucgPathIsMediaUri(path);

Future<bool> _hasValidMediaInfo(String path) async {
  try {
    final info = await VideoCompress.getMediaInfo(path);
    final duration = info.duration ?? 0;
    final size = info.filesize ?? 0;
    return duration > 50 && size > 16384;
  } catch (_) {
    return false;
  }
}

Future<bool> _isReadableFile(File file) async {
  try {
    if (!await file.exists()) return false;
    await file.openRead(0, 1).first;
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> _isPlausibleMediaFile(File file, {int minBytes = 4096}) async {
  try {
    if (!await file.exists()) return false;
    return await file.length() >= minBytes;
  } catch (_) {
    return false;
  }
}

String _extFromPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot <= 0 || dot >= path.length - 1) return '.mp4';
  final ext = path.substring(dot);
  return ext.length <= 8 ? ext : '.mp4';
}

Future<File> _playCacheFileAsync(String source) async {
  final dir = await getTemporaryDirectory();
  final key = '${source.hashCode.abs()}_${source.length}';
  return File('${dir.path}/ucg_play_$key.mp4');
}

/// 将不可直接读取的媒体路径复制到应用临时目录（供播放/压缩使用）。
Future<String?> ucgCacheMediaPath(String path) async {
  if (path.isEmpty || kIsWeb) return null;
  try {
    final dir = await getTemporaryDirectory();
    final dest = File(
      '${dir.path}/ucg_media_${DateTime.now().microsecondsSinceEpoch}${_extFromPath(path)}',
    );
    if (ucgPathIsMediaUri(path)) {
      await XFile(path).saveTo(dest.path);
    } else {
      final src = File(path);
      if (await _isReadableFile(src)) {
        await src.copy(dest.path);
      } else {
        await XFile(path).saveTo(dest.path);
      }
    }
    if (await _isPlausibleMediaFile(dest)) return dest.path;
  } catch (_) {}
  return null;
}

/// 创建可播放的 [VideoPlayerController]（处理 Android `content://` 与无权限直读路径）。
Future<VideoPlayerController?> ucgCreateVideoPlayerController({
  String? localPath,
  String? videoUrl,
}) async {
  if (videoUrl != null && videoUrl.isNotEmpty) {
    return VideoPlayerController.networkUrl(Uri.parse(videoUrl));
  }
  final path = localPath;
  if (path == null || path.isEmpty) return null;

  if (kIsWeb) {
    if (path.startsWith('blob:') || path.startsWith('http')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    }
    return null;
  }

  if (path.startsWith('content://')) {
    if (Platform.isAndroid) {
      return VideoPlayerController.contentUri(Uri.parse(path));
    }
    final cached = await ucgCacheMediaPath(path);
    if (cached != null) return VideoPlayerController.file(File(cached));
    return null;
  }

  if (path.startsWith('file://')) {
    final filePath = Uri.parse(path).toFilePath();
    final file = File(filePath);
    if (await _isReadableFile(file)) {
      return VideoPlayerController.file(file);
    }
    final cached = await ucgCacheMediaPath(path);
    if (cached != null) return VideoPlayerController.file(File(cached));
    return null;
  }

  final file = File(path);
  if (await _isReadableFile(file)) {
    return VideoPlayerController.file(file);
  }

  final cached = await ucgCacheMediaPath(path);
  if (cached != null) return VideoPlayerController.file(File(cached));
  return null;
}

/// 提取视频封面（不经过 ExoPlayer）。优先由选图阶段 [photo_manager] 注入 bytes。
Future<Uint8List?> ucgLoadVideoThumbnailBytes(
  String path, {
  int quality = 75,
}) async {
  if (path.isEmpty || kIsWeb) return null;
  var source = path;
  if (ucgPathIsMediaUri(path) || path.startsWith('/storage/')) {
    final cached = await ucgCacheMediaPath(path);
    if (cached == null || cached.isEmpty) return null;
    source = cached;
  }
  try {
    final bytes = await VideoCompress.getByteThumbnail(
      source,
      quality: quality,
      position: 0,
    );
    if (bytes != null && bytes.isNotEmpty) return bytes;
  } catch (_) {}
  return null;
}

/// 解析可供转码的本地文件路径（禁止把 `content://` 直接交给转码器）。
Future<String?> ucgResolveVideoSourcePath(String path) async {
  if (path.isEmpty || kIsWeb) return null;
  if (_isAppSandboxPath(path)) {
    if (await _hasValidMediaInfo(path)) return path;
    if (await _isPlausibleMediaFile(File(path))) return path;
  }
  if (ucgPathIsMediaUri(path) || path.startsWith('/storage/')) {
    return ucgCacheMediaPath(path);
  }
  final file = File(path);
  if (await _hasValidMediaInfo(path)) return path;
  if (await _isPlausibleMediaFile(file)) return path;
  return ucgCacheMediaPath(path);
}

Future<void> _deleteFileIfExists(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

Future<bool> _isLikelyTranscoded(String outPath, String sourcePath) async {
  if (outPath.isEmpty || outPath == sourcePath) return false;
  try {
    final outInfo = await VideoCompress.getMediaInfo(outPath);
    final srcInfo = await VideoCompress.getMediaInfo(sourcePath);
    final outW = outInfo.width ?? 0;
    final srcW = srcInfo.width ?? 0;
    final outH = outInfo.height ?? 0;
    final srcH = srcInfo.height ?? 0;
    final outSize = outInfo.filesize ?? 0;
    final srcSize = srcInfo.filesize ?? 0;
    if (outW > 0 && srcW > 0 && (outW < srcW || outH < srcH)) return true;
    if (outSize > 0 && srcSize > 0 && outSize < (srcSize * 0.9).round()) return true;
    return outSize > 16384;
  } catch (_) {
    return outPath != sourcePath;
  }
}

/// 转码并缓存可播放路径（Android 本地视频播放用，规避海思硬解失败）。
Future<String?> ucgTranscodedPlayPath(
  String path, {
  bool skipCache = false,
}) async {
  if (path.isEmpty || kIsWeb) return null;
  final source = await ucgResolveVideoSourcePath(path);
  if (source == null || source.isEmpty) return null;

  try {
    final cacheFile = await _playCacheFileAsync(source);
    if (!skipCache &&
        await _isPlausibleMediaFile(cacheFile, minBytes: 32768) &&
        await _hasValidMediaInfo(cacheFile.path) &&
        await _isLikelyTranscoded(cacheFile.path, source)) {
      _ucgVideoLog('reuse transcoded cache ${cacheFile.path}');
      return cacheFile.path;
    }
    if (skipCache) await _deleteFileIfExists(cacheFile.path);

    const attempts = <({VideoQuality quality, bool includeAudio, int frameRate})>[
      (quality: VideoQuality.LowQuality, includeAudio: false, frameRate: 24),
      (quality: VideoQuality.LowQuality, includeAudio: true, frameRate: 24),
      (quality: VideoQuality.Res640x480Quality, includeAudio: false, frameRate: 24),
      (quality: VideoQuality.Res640x480Quality, includeAudio: true, frameRate: 24),
      (quality: VideoQuality.DefaultQuality, includeAudio: false, frameRate: 30),
      (quality: VideoQuality.MediumQuality, includeAudio: true, frameRate: 30),
    ];
    for (final attempt in attempts) {
      _ucgVideoLog(
        'transcode source=$source quality=${attempt.quality} audio=${attempt.includeAudio}',
      );
      final info = await VideoCompress.compressVideo(
        source,
        quality: attempt.quality,
        deleteOrigin: false,
        includeAudio: attempt.includeAudio,
        frameRate: attempt.frameRate,
      );
      final out = info?.file?.path;
      if (out == null || out.isEmpty) continue;
      if (!await _isLikelyTranscoded(out, source)) {
        await _deleteFileIfExists(out);
        continue;
      }
      if (!await _hasValidMediaInfo(out) &&
          !await _isPlausibleMediaFile(File(out), minBytes: 32768)) {
        await _deleteFileIfExists(out);
        continue;
      }

      try {
        await File(out).copy(cacheFile.path);
      } catch (_) {}
      _ucgVideoLog('transcode ok out=$out');
      return out;
    }
    _ucgVideoLog('transcode failed for source=$source');
  } catch (_) {}
  return null;
}

String _transcodeInputPath(String path, String? contentUri) {
  if (path.isNotEmpty && !path.startsWith('content://')) return path;
  if (contentUri != null && contentUri.isNotEmpty) return contentUri;
  return path;
}

/// 初始化本地视频控制器；Android 仅走转码文件（规避海思硬解），iOS 可回退 contentUri。
Future<VideoPlayerController?> ucgInitializeLocalVideoPlayer(
  String path, {
  String? contentUri,
  bool forceTranscodeOnly = false,
}) async {
  if (path.isEmpty && (contentUri == null || contentUri.isEmpty)) return null;
  if (kIsWeb) return null;

  Future<VideoPlayerController?> tryInitFile(String playPath) async {
    final controller = VideoPlayerController.file(File(playPath));
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      await controller.pause();
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'playback');
      }
      return controller;
    } catch (_) {
      await controller.dispose();
      await _androidCodecCooldown();
      return null;
    }
  }

  Future<VideoPlayerController?> playTranscoded(
    String transcodePath, {
    required bool skipCache,
  }) async {
    final source = await ucgResolveVideoSourcePath(transcodePath);
    final playPath = await ucgTranscodedPlayPath(transcodePath, skipCache: skipCache);
    if (playPath == null) return null;
    final ready = await tryInitFile(playPath);
    if (ready != null) return ready;
    await _deleteFileIfExists(playPath);
    if (source != null) {
      final cacheFile = await _playCacheFileAsync(source);
      await _deleteFileIfExists(cacheFile.path);
    }
    await _androidCodecCooldown();
    return null;
  }

  final transcodeInput = _transcodeInputPath(path, contentUri);

  if (Platform.isAndroid) {
    if (transcodeInput.isEmpty) return null;
    if (forceTranscodeOnly) {
      return playTranscoded(transcodeInput, skipCache: true);
    }
    final first = await playTranscoded(transcodeInput, skipCache: false);
    if (first != null) return first;
    await _androidCodecCooldown();
    return playTranscoded(transcodeInput, skipCache: true);
  }

  Future<VideoPlayerController?> tryContentUri(String? uri) async {
    if (uri == null || !uri.startsWith('content://')) return null;
    final controller = VideoPlayerController.contentUri(Uri.parse(uri));
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      await controller.pause();
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'playback');
      }
      return controller;
    } catch (_) {
      await controller.dispose();
      await _androidCodecCooldown();
      return null;
    }
  }

  final uri = contentUri ?? (path.startsWith('content://') ? path : null);

  if (path.isNotEmpty) {
    final primary = await ucgCreateVideoPlayerController(localPath: path);
    if (primary != null) {
      try {
        await primary.initialize();
        return primary;
      } catch (_) {
        await primary.dispose();
      }
    }
    if (transcodeInput.isNotEmpty) {
      return playTranscoded(transcodeInput, skipCache: true);
    }
  }
  return tryContentUri(uri);
}
