import 'apk_update_impl.dart' if (dart.library.html) 'apk_update_stub.dart' as impl;

/// Web 为 stub 抛错；Android/iOS 走 IO 实现（仅 Android 内会真正安装）。
Future<void> downloadAndInstallApkFromUrl(
  String url, {
  void Function(double? fraction)? onProgress,
}) =>
    impl.downloadAndInstallApkFromUrl(url, onProgress: onProgress);
