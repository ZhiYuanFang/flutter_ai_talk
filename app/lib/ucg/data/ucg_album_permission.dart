import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// 相册权限：Web 跳过；原生用 photo_manager + permission_handler。
Future<bool> ucgEnsureAlbumPermission() async {
  if (kIsWeb) return true;

  final state = await PhotoManager.requestPermissionExtend();
  if (state.isAuth || state.hasAccess) {
    PhotoManager.setIgnorePermissionCheck(true);
    return true;
  }

  if (state.isLimited) {
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

Future<bool> ucgOpenAppSettingsForAlbum() => openAppSettings();
