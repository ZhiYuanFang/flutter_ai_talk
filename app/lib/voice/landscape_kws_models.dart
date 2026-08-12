import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../api/app_debug_log.dart';

/// 横屏 KWS 模型目录名（与 CDN mobile 包顶层目录一致）。
const kLandscapeKwsModelDirName =
    'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile';

/// 自有 CDN mobile 压缩包（首次进横屏下载一次，约 15MB）。
const kLandscapeKwsModelArchiveUrl =
    'https://resorce.cuplay.top/app/models/kws/'
    'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile.tar.bz2';

/// 「你好，胖宝」ppinyin 关键词行（Wenetspeech KWS tokens_type=ppinyin）。
const kLandscapeWakeKeywordsPinyin =
    'n ǐ h ǎo p àng b ǎo :2.0 #0.25 @你好胖宝\n';

/// 解析后的本地模型文件路径。
class LandscapeKwsModelPaths {
  const LandscapeKwsModelPaths({
    required this.encoder,
    required this.decoder,
    required this.joiner,
    required this.tokens,
    required this.keywords,
  });

  final String encoder;
  final String decoder;
  final String joiner;
  final String tokens;
  final String keywords;
}

/// 确保 Wenetspeech 中文 KWS 模型落在应用支持目录；缺失则下载并解压。
Future<LandscapeKwsModelPaths?> ensureLandscapeKwsModels({
  void Function(String status)? onStatus,
}) async {
  final support = await getApplicationSupportDirectory();
  final root = Directory(
    '${support.path}${Platform.pathSeparator}$kLandscapeKwsModelDirName',
  );
  final paths = _pathsFor(root.path);
  if (await _isComplete(paths)) {
    await _ensureKeywordsFile(paths.keywords);
    return paths;
  }

  onStatus?.call('正在下载唤醒模型…');
  final tmpDir = await getTemporaryDirectory();
  final archivePath =
      '${tmpDir.path}${Platform.pathSeparator}$kLandscapeKwsModelDirName.tar.bz2';
  try {
    final ok = await _downloadArchiveWithProgress(
      url: kLandscapeKwsModelArchiveUrl,
      destPath: archivePath,
      onStatus: onStatus,
    );
    if (!ok) {
      onStatus?.call('唤醒模型下载失败');
      return null;
    }

    onStatus?.call('正在解压唤醒模型…');
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
    await root.parent.create(recursive: true);

    // 纯 Dart 解压 tar.bz2（手机无系统 tar）。
    final bzBytes = await File(archivePath).readAsBytes();
    final tarBytes = BZip2Decoder().decodeBytes(bzBytes);
    final archive = TarDecoder().decodeBytes(tarBytes);
    for (final file in archive.files) {
      final outPath =
          '${root.parent.path}${Platform.pathSeparator}${file.name}';
      if (file.isFile) {
        final out = File(outPath);
        await out.parent.create(recursive: true);
        await out.writeAsBytes(file.content, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    final after = _pathsFor(root.path);
    if (!await _isComplete(after)) {
      final missing = _missingBasenames(after);
      AppDebugLog.landscapeKws('incomplete after extract missing=$missing');
      onStatus?.call('唤醒模型不完整');
      return null;
    }
    await _ensureKeywordsFile(after.keywords);
    AppDebugLog.landscapeKws('ready encoder=${_basename(after.encoder)} '
        'decoder=${_basename(after.decoder)} joiner=${_basename(after.joiner)}');
    return after;
  } catch (e) {
    AppDebugLog.landscapeKws('prepare err=$e');
    onStatus?.call('唤醒模型准备失败');
    return null;
  } finally {
    try {
      await File(archivePath).delete();
    } catch (_) {}
  }
}

/// 分件 prefer int8，否则该件用 fp32（允许 mobile 混合精度）。
LandscapeKwsModelPaths _pathsFor(String root) {
  String pick(String stem) {
    final int8 = '$root${Platform.pathSeparator}$stem.int8.onnx';
    final fp32 = '$root${Platform.pathSeparator}$stem.onnx';
    if (File(int8).existsSync()) return int8;
    return fp32;
  }

  const encStem = 'encoder-epoch-12-avg-2-chunk-16-left-64';
  const decStem = 'decoder-epoch-12-avg-2-chunk-16-left-64';
  const joinStem = 'joiner-epoch-12-avg-2-chunk-16-left-64';
  return LandscapeKwsModelPaths(
    encoder: pick(encStem),
    decoder: pick(decStem),
    joiner: pick(joinStem),
    tokens: '$root${Platform.pathSeparator}tokens.txt',
    keywords: '$root${Platform.pathSeparator}pangbao_keywords.txt',
  );
}

Future<bool> _isComplete(LandscapeKwsModelPaths p) async {
  return File(p.encoder).existsSync() &&
      File(p.decoder).existsSync() &&
      File(p.joiner).existsSync() &&
      File(p.tokens).existsSync();
}

String _basename(String path) {
  final i = path.replaceAll('\\', '/').lastIndexOf('/');
  return i < 0 ? path : path.substring(i + 1);
}

String _missingBasenames(LandscapeKwsModelPaths p) {
  final missing = <String>[];
  if (!File(p.encoder).existsSync()) missing.add(_basename(p.encoder));
  if (!File(p.decoder).existsSync()) missing.add(_basename(p.decoder));
  if (!File(p.joiner).existsSync()) missing.add(_basename(p.joiner));
  if (!File(p.tokens).existsSync()) missing.add('tokens.txt');
  return missing.join(',');
}

Future<void> _ensureKeywordsFile(String path) async {
  final f = File(path);
  await f.writeAsString(kLandscapeWakeKeywordsPinyin, flush: true);
}

/// 流式下载并节流上报进度（有 Content-Length 显示 %，否则显示已下 MB）。
Future<bool> _downloadArchiveWithProgress({
  required String url,
  required String destPath,
  void Function(String status)? onStatus,
}) async {
  final client = http.Client();
  try {
    final req = http.Request('GET', Uri.parse(url));
    final res = await client.send(req);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      AppDebugLog.landscapeKws('download http=${res.statusCode} url=$url');
      return false;
    }

    final total = res.contentLength ?? -1;
    final sink = File(destPath).openWrite();
    var received = 0;
    var lastPct = -1;
    var lastMbTenths = -1;
    var lastEmitAt = DateTime.fromMillisecondsSinceEpoch(0);

    await for (final chunk in res.stream) {
      sink.add(chunk);
      received += chunk.length;
      final now = DateTime.now();
      final elapsedMs = now.difference(lastEmitAt).inMilliseconds;

      if (total > 0) {
        final pct = ((received * 100) / total).floor().clamp(0, 100);
        // 每涨 1% 或至少间隔 250ms 再刷 UI，避免刷爆 chip。
        if (pct != lastPct && (pct == 100 || elapsedMs >= 250)) {
          lastPct = pct;
          lastEmitAt = now;
          onStatus?.call('正在下载唤醒模型 $pct%');
        }
      } else {
        final mbTenths = (received / (1024 * 1024) * 10).floor();
        if (mbTenths != lastMbTenths && elapsedMs >= 250) {
          lastMbTenths = mbTenths;
          lastEmitAt = now;
          final mb = (received / (1024 * 1024)).toStringAsFixed(1);
          onStatus?.call('正在下载唤醒模型 ${mb}MB');
        }
      }
    }
    await sink.flush();
    await sink.close();

    if (total > 0) {
      onStatus?.call('正在下载唤醒模型 100%');
    }
    if (received <= 0) {
      AppDebugLog.landscapeKws('download empty body url=$url');
      return false;
    }
    AppDebugLog.landscapeKws('download ok bytes=$received total=$total');
    return true;
  } catch (e) {
    AppDebugLog.landscapeKws('download err=$e');
    try {
      await File(destPath).delete();
    } catch (_) {}
    return false;
  } finally {
    client.close();
  }
}
