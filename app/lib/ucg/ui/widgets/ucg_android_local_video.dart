import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _localVideoChannel = MethodChannel('com.fzy.pangbao/local_video');
const _localVideoEvents = EventChannel('com.fzy.pangbao/local_video/events');

bool ucgUseAndroidNativeLocalVideo({
  String? videoUrl,
  String? filePath,
  String? contentUri,
}) {
  if (kIsWeb || !Platform.isAndroid) return false;
  if (videoUrl != null && videoUrl.isNotEmpty) return false;
  return (filePath != null && filePath.isNotEmpty) ||
      (contentUri != null && contentUri.isNotEmpty);
}

/// 内联/全屏播放失败时打开系统或外链播放器（含 https CDN）。
Future<bool> ucgOpenExternalVideoPlayer({
  String? videoUrl,
  String? filePath,
  String? contentUri,
}) async {
  if (videoUrl != null && videoUrl.isNotEmpty) {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  return ucgOpenSystemVideoPlayer(filePath: filePath, contentUri: contentUri);
}

/// 打开外链/系统播放器；失败时 SnackBar 提示。
Future<void> ucgOpenExternalVideoPlayerWithFeedback(
  BuildContext context, {
  String? videoUrl,
  String? filePath,
  String? contentUri,
}) async {
  final ok = await ucgOpenExternalVideoPlayer(
    videoUrl: videoUrl,
    filePath: filePath,
    contentUri: contentUri,
  );
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('无法打开系统播放器')),
  );
}

Future<bool> ucgOpenSystemVideoPlayer({
  String? videoUrl,
  String? filePath,
  String? contentUri,
}) async {
  if (kIsWeb || !Platform.isAndroid) return false;
  if ((videoUrl == null || videoUrl.isEmpty) &&
      (filePath == null || filePath.isEmpty) &&
      (contentUri == null || contentUri.isEmpty)) {
    return false;
  }
  try {
    await _localVideoChannel.invokeMethod<void>('openSystemPlayer', {
      'videoUrl': videoUrl,
      'filePath': filePath,
      'contentUri': contentUri,
    });
    return true;
  } catch (_) {
    return false;
  }
}

/// Android 本地视频：原生 [VideoView]（MediaPlayer），规避 ExoPlayer 在海思上的硬解失败。
class UcgAndroidLocalVideoView extends StatefulWidget {
  const UcgAndroidLocalVideoView({
    super.key,
    this.filePath,
    this.contentUri,
    this.onReady,
    this.onFailed,
  });

  final String? filePath;
  final String? contentUri;
  final VoidCallback? onReady;
  final VoidCallback? onFailed;

  @override
  State<UcgAndroidLocalVideoView> createState() => _UcgAndroidLocalVideoViewState();
}

class _UcgAndroidLocalVideoViewState extends State<UcgAndroidLocalVideoView> {
  StreamSubscription<dynamic>? _events;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _events = _localVideoEvents.receiveBroadcastStream().listen(
      (event) {
        if (event is Map && event['event'] == 'prepared') {
          widget.onReady?.call();
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _failed = true);
        widget.onFailed?.call();
      },
    );
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    return AndroidView(
      viewType: 'ucg-local-video',
      layoutDirection: TextDirection.ltr,
      creationParams: <String, String?>{
        'filePath': widget.filePath,
        'contentUri': widget.contentUri,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
