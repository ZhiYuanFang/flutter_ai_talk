import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../api/app_debug_log.dart';
import 'ucg_album_permission.dart';

/// 相册写入/添加权限（与读相册选图区分）。
Future<bool> ucgEnsureAlbumWritePermission() async {
  if (kIsWeb) return false;

  final state = await PhotoManager.requestPermissionExtend();
  if (state.isAuth || state.hasAccess || state.isLimited) {
    PhotoManager.setIgnorePermissionCheck(true);
    return true;
  }

  // iOS 14+ 可仅申请添加
  final addOnly = await Permission.photosAddOnly.request();
  if (addOnly.isGranted || addOnly.isLimited) {
    PhotoManager.setIgnorePermissionCheck(true);
    return true;
  }

  final photos = await Permission.photos.request();
  if (photos.isGranted || photos.isLimited) {
    PhotoManager.setIgnorePermissionCheck(true);
    return true;
  }

  return false;
}

/// 将图片字节写入系统相册。
///
/// [ensurePermission] 为 false 时由调用方已完成写权限门闸。
Future<bool> ucgSaveImageBytesToAlbum(
  Uint8List bytes, {
  String filename = 'pangbao.jpg',
  bool ensurePermission = true,
}) async {
  if (kIsWeb) return false;
  if (bytes.isEmpty) return false;
  if (ensurePermission) {
    final ok = await ucgEnsureAlbumWritePermission();
    if (!ok) return false;
  }
  try {
    await PhotoManager.editor.saveImage(
      bytes,
      filename: filename,
      title: filename,
    );
    return true;
  } catch (e) {
    AppDebugLog.ucgFeed('saveImage to album fail err=$e');
    return false;
  }
}

/// 从本地路径读取字节。
Future<Uint8List?> ucgReadImageFileBytes(String path) async {
  if (kIsWeb || path.isEmpty) return null;
  try {
    final f = File(path);
    if (!await f.exists()) return null;
    final bytes = await f.readAsBytes();
    return bytes.isEmpty ? null : bytes;
  } catch (e) {
    AppDebugLog.ucgFeed('read image file fail err=$e');
    return null;
  }
}

/// 下载远程图字节（保存相册用）。
Future<Uint8List?> ucgFetchImageBytes(String url) async {
  final u = url.trim();
  if (u.isEmpty) return null;
  try {
    final res = await http.get(Uri.parse(u));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      AppDebugLog.ucgFeed('fetch image http=${res.statusCode}');
      return null;
    }
    final bytes = res.bodyBytes;
    return bytes.isEmpty ? null : bytes;
  } catch (e) {
    AppDebugLog.ucgFeed('fetch image fail err=$e');
    return null;
  }
}

/// 解析可保存的图片字节：优先内存 → 本地文件 → 磁盘缓存 → HTTP。
Future<Uint8List?> ucgResolveImageBytesForAlbum({
  String? url,
  String? filePath,
  Uint8List? bytes,
}) async {
  if (bytes != null && bytes.isNotEmpty) return bytes;

  final path = filePath?.trim() ?? '';
  if (path.isNotEmpty) {
    final fromFile = await ucgReadImageFileBytes(path);
    if (fromFile != null) return fromFile;
  }

  final u = url?.trim() ?? '';
  if (u.isEmpty) return null;

  try {
    final cached = await DefaultCacheManager().getSingleFile(u);
    final fromCache = await cached.readAsBytes();
    if (fromCache.isNotEmpty) return fromCache;
  } catch (e) {
    AppDebugLog.ucgFeed('album resolve cache miss err=$e');
  }

  return ucgFetchImageBytes(u);
}

String ucgAlbumFilenameFromUrl(String? url) {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) {
    return 'pangbao_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
  try {
    final segs = Uri.parse(raw).pathSegments;
    if (segs.isNotEmpty) {
      final name = segs.last;
      if (name.contains('.')) return name;
    }
  } catch (_) {}
  return 'pangbao_${DateTime.now().millisecondsSinceEpoch}.jpg';
}

/// 打开系统设置（复用读相册辅助）。
Future<bool> ucgOpenAlbumSettings() => ucgOpenAppSettingsForAlbum();
