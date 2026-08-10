import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 宝宝头像本地副本：`documents/baby_avatar/{babyId}.*` + prefs 相对路径。
/// 与 [EventMediaLocalStore] 的 `history_media/` 隔离，清历史媒体不得扫描本目录。
class BabyAvatarLocalStore {
  static const _keyPrefix = 'baby_avatar_local_v1_';
  static const _mediaRoot = 'baby_avatar';

  static String _prefsKey(String babyId) => '$_keyPrefix$babyId';

  /// 读取相对路径（相对 application documents）。
  static Future<String?> loadRelativePath(String babyId) async {
    if (babyId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(babyId));
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// 解析本地文件；不存在则返回 null。
  static Future<File?> resolveFile(String babyId) async {
    if (babyId.isEmpty || kIsWeb) return null;
    final relative = await loadRelativePath(babyId);
    if (relative == null || relative.isEmpty) return null;
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$relative');
    if (!await file.exists()) return null;
    return file;
  }

  /// 将 [source] 复制到 `baby_avatar/{babyId}{ext}`，覆盖旧文件并更新 prefs。
  static Future<File?> persistAvatar({
    required String babyId,
    required File source,
  }) async {
    if (babyId.isEmpty || kIsWeb) return null;
    if (!await source.exists()) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_mediaRoot');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 先删旧映射文件（含不同扩展名）
    await clearAvatar(babyId);

    final ext = _fileExtension(source.path);
    final name = '$babyId${ext.isEmpty ? '.jpg' : ext}';
    final relativePath = '$_mediaRoot/$name';
    final dest = File('${docs.path}/$relativePath');
    await source.copy(dest.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(babyId), relativePath);
    return dest;
  }

  /// 删除指定宝宝头像文件与 prefs（换绑时用）。
  static Future<void> clearAvatar(String babyId) async {
    if (babyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final relative = prefs.getString(_prefsKey(babyId));
    await prefs.remove(_prefsKey(babyId));
    if (kIsWeb || relative == null || relative.isEmpty) return;
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$relative');
    if (await file.exists()) {
      await file.delete();
    }
  }
}

String _fileExtension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot >= path.length - 1) return '';
  return path.substring(dot);
}
