import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('com.pangbao.pangbao_app/installer');

/// 下载 APK 到应用临时目录下的 `apk_updates/`，再经原生通道调起安装。
Future<void> downloadAndInstallApkFromUrl(
  String url, {
  void Function(double? fraction)? onProgress,
}) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('APK 安装仅支持 Android');
  }
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    throw ArgumentError('无效的下载地址');
  }

  final temp = await getTemporaryDirectory();
  final dir = Directory('${temp.path}/apk_updates');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}/pangbao_update.apk');
  if (await file.exists()) {
    await file.delete();
  }

  final client = http.Client();
  try {
    final request = http.Request('GET', uri);
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw HttpException('下载失败 HTTP ${response.statusCode}');
    }
    final sink = file.openWrite();
    final total = response.contentLength;
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (total != null && total > 0) {
          onProgress?.call(received / total);
        } else {
          onProgress?.call(null);
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  } finally {
    client.close();
  }

  final canInstall = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
  if (canInstall == false) {
    await _channel.invokeMethod<void>('openInstallPermissionSettings');
    throw StateError('请在系统设置中允许本应用「安装未知应用」后重试');
  }

  try {
    await _channel.invokeMethod<void>('installApk', {'path': file.path});
  } on PlatformException catch (e) {
    throw Exception(e.message ?? e.code);
  }
}
